from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from app.database import get_session
from app.models.user import User, UserRole
from app.schemas.user import RegisterRequest, UserRead, UserUpdate
from app.schemas.auth import Token, LoginRequest, ForgotPasswordRequest, VerifyCodeRequest, ResetPasswordRequest
import random
import string
import uuid

# In-memory storage for OTPs and reset tokens (for demonstration)
otp_cache = {}  # dict of email -> str (OTP)
reset_token_cache = {}  # dict of token -> email
from app.core.security import hash_password, verify_password, create_access_token
from app.core.deps import get_current_user, get_current_user_allow_inactive
from pydantic import BaseModel
from datetime import datetime

router = APIRouter(prefix="/auth", tags=["Auth"])


class AppealRequest(BaseModel):
    appeal_message: str


@router.post("/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, session: Annotated[Session, Depends(get_session)]):
    """
    Register a new user (student/client) account.
    - Admin self-registration is rejected.
    """
    if payload.role == UserRole.admin:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot register as admin."
        )

    # Check if email already taken
    existing = session.exec(select(User).where(User.email == payload.email)).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    # Create user
    user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        role=UserRole.client,
        first_name=payload.first_name,
        last_name=payload.last_name,
        phone_number=payload.phone_number,
        birthday=payload.birthday,
        gender=payload.gender,
        address=payload.address,
        bio=payload.bio,
        avatar_url=payload.avatar_url,
        occupation=payload.occupation,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(credentials: LoginRequest, session: Annotated[Session, Depends(get_session)]):
    """Verify email + password and return a JWT access token."""
    user = session.exec(select(User).where(User.email == credentials.email)).first()
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if user.is_deleted:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deleted or archived. Please contact the Guidance Office for restoration.",
        )

    role_str = user.role.value if hasattr(user.role, "value") else str(user.role)
    token = create_access_token(data={"sub": str(user.id), "role": role_str})
    return Token(access_token=token)


@router.get("/me", response_model=UserRead)
def me(current_user: Annotated[User, Depends(get_current_user_allow_inactive)]):
    """Return the currently authenticated user's profile (including deactivated status)."""
    return current_user


@router.post("/appeal")
def submit_reactivation_appeal(
    payload: AppealRequest,
    current_user: Annotated[User, Depends(get_current_user_allow_inactive)],
    session: Annotated[Session, Depends(get_session)],
):
    """Allow a deactivated user to submit an appeal to the guidance center."""
    current_user.reactivation_appeal = payload.appeal_message.strip()
    current_user.reactivation_appeal_at = datetime.utcnow()
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    return {"message": "Reactivation appeal submitted successfully to the Guidance Office."}


@router.put("/me", response_model=UserRead)
def update_me(payload: UserUpdate, current_user: Annotated[User, Depends(get_current_user)], session: Annotated[Session, Depends(get_session)]):
    """Update the currently authenticated user's profile."""
    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(current_user, key, value)
    
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    
    return current_user


@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest, session: Annotated[Session, Depends(get_session)]):
    """Generate and send a 6-digit OTP for password reset."""
    user = session.exec(select(User).where(User.email == payload.email)).first()
    if not user:
        # Prevent email enumeration by returning a success message anyway
        return {"message": "If that email is registered, we have sent a verification code."}
    
    # Generate 6-digit OTP
    otp = ''.join(random.choices(string.digits, k=6))
    otp_cache[payload.email] = otp
    
    # In a real app, send this via email/SMS here. We'll just print it.
    print(f"--- MOCK EMAIL --- Sent OTP {otp} to {payload.email}")
    
    return {"message": "If that email is registered, we have sent a verification code."}


@router.post("/verify-code")
def verify_code(payload: VerifyCodeRequest):
    """Verify the 6-digit OTP and issue a reset token."""
    expected_otp = otp_cache.get(payload.email)
    if not expected_otp or expected_otp != payload.code:
        raise HTTPException(status_code=400, detail="Invalid or expired verification code.")
    
    # OTP is valid, generate a temporary reset token
    reset_token = str(uuid.uuid4())
    reset_token_cache[reset_token] = payload.email
    
    # Remove OTP so it can't be reused
    del otp_cache[payload.email]
    
    return {"message": "Code verified", "reset_token": reset_token}


@router.post("/reset-password")
def reset_password(payload: ResetPasswordRequest, session: Annotated[Session, Depends(get_session)]):
    """Set a new password using a valid reset token."""
    email = reset_token_cache.get(payload.reset_token)
    if not email:
        raise HTTPException(status_code=400, detail="Invalid or expired reset token.")
    
    user = session.exec(select(User).where(User.email == email)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    
    # Update password
    user.hashed_password = hash_password(payload.new_password)
    session.add(user)
    session.commit()
    
    # Invalidate token
    del reset_token_cache[payload.reset_token]
    
    return {"message": "Password successfully reset."}


@router.put("/change-password")
def change_password(
    payload: dict,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)]
):
    """Change password for the currently authenticated user."""
    old_password = payload.get("old_password", "")
    new_password = payload.get("new_password", "")

    if not verify_password(old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect.")

    if len(new_password) < 8:
        raise HTTPException(status_code=400, detail="New password must be at least 8 characters.")

    current_user.hashed_password = hash_password(new_password)
    session.add(current_user)
    session.commit()

    return {"message": "Password changed successfully."}
