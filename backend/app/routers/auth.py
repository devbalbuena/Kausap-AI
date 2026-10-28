from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from app.database import get_session
from app.models.user import User, UserRole
from app.schemas.user import RegisterRequest, UserRead, UserUpdate
from app.schemas.auth import Token, RegisterResponse, LoginRequest, ForgotPasswordRequest, VerifyCodeRequest, ResetPasswordRequest
import random
import string
import uuid
from datetime import datetime, timezone, timedelta

from app.core.security import hash_password, verify_password, create_access_token
from app.core.deps import get_current_user, get_current_user_allow_inactive
from pydantic import BaseModel, Field

# ── In-memory OTP / reset-token stores with TTL and brute-force protection ─────
# Each entry: { 'otp': str, 'expires_at': datetime, 'attempts': int }
otp_cache: dict = {}        # email -> { otp, expires_at, attempts }
reset_token_cache: dict = {}  # token  -> email

_OTP_TTL_MINUTES = 10       # OTP valid for 10 minutes
_OTP_MAX_ATTEMPTS = 3       # Lock after 3 wrong guesses


def _utcnow() -> datetime:
    """Return a timezone-aware UTC datetime."""
    return datetime.now(timezone.utc)


router = APIRouter(prefix="/auth", tags=["Auth"])


class AppealRequest(BaseModel):
    appeal_message: str


class ChangePasswordRequest(BaseModel):
    old_password: str = Field(min_length=1)
    new_password: str = Field(min_length=8, description="New password (minimum 8 characters)")


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, session: Annotated[Session, Depends(get_session)]):
    """
    Register a new user (student/client) account.
    - Admin self-registration is rejected.
    - Returns JWT access token and user profile in 1 shot (eliminates duplicate login roundtrip).
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
        nationality=payload.nationality or "Filipino",
        hobbies=payload.hobbies,
        occupation=payload.occupation,
        college=payload.college,
    )
    session.add(user)
    session.commit()
    session.refresh(user)

    role_str = user.role.value if hasattr(user.role, "value") else str(user.role)
    token = create_access_token(data={"sub": str(user.id), "role": role_str})
    return RegisterResponse(access_token=token, token_type="bearer", user=UserRead.model_validate(user))


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
    current_user.reactivation_appeal_at = _utcnow().replace(tzinfo=None)
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    return {"message": "Reactivation appeal submitted successfully to the Guidance Office."}


@router.put("/me", response_model=UserRead)
def update_me(payload: UserUpdate, current_user: Annotated[User, Depends(get_current_user)], session: Annotated[Session, Depends(get_session)]):
    """Update the currently authenticated user's profile."""
    update_data = payload.model_dump(exclude_unset=True)
    
    # One-time college setup for existing users whose college is not set yet
    if "college" in update_data:
        new_college = update_data.pop("college")
        if (current_user.college is None or current_user.college == "") and new_college:
            current_user.college = new_college

    for key, value in update_data.items():
        setattr(current_user, key, value)
    
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    
    return current_user


@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest, session: Annotated[Session, Depends(get_session)]):
    """Generate and send a 6-digit OTP for password reset (expires in 10 minutes)."""
    user = session.exec(select(User).where(User.email == payload.email)).first()
    if not user:
        # Prevent email enumeration — always return the same message
        return {"message": "If that email is registered, we have sent a verification code."}

    otp = ''.join(random.choices(string.digits, k=6))
    otp_cache[payload.email] = {
        "otp": otp,
        "expires_at": _utcnow() + timedelta(minutes=_OTP_TTL_MINUTES),
        "attempts": 0,
    }

    # In production: send via email/SMS. Printed here for development.
    print(f"--- MOCK EMAIL --- Sent OTP {otp} to {payload.email} (valid {_OTP_TTL_MINUTES} min)")

    return {"message": "If that email is registered, we have sent a verification code."}


@router.post("/verify-code")
def verify_code(payload: VerifyCodeRequest):
    """Verify the 6-digit OTP (with expiry + attempt limit) and issue a one-time reset token."""
    record = otp_cache.get(payload.email)

    if not record:
        raise HTTPException(status_code=400, detail="Invalid or expired verification code.")

    # Check TTL expiry
    if _utcnow() > record["expires_at"]:
        del otp_cache[payload.email]
        raise HTTPException(status_code=400, detail="Verification code has expired. Please request a new one.")

    # Brute-force guard: lock after max attempts
    if record["attempts"] >= _OTP_MAX_ATTEMPTS:
        del otp_cache[payload.email]
        raise HTTPException(status_code=429, detail="Too many incorrect attempts. Please request a new verification code.")

    if record["otp"] != payload.code:
        record["attempts"] += 1
        remaining = _OTP_MAX_ATTEMPTS - record["attempts"]
        raise HTTPException(
            status_code=400,
            detail=f"Invalid verification code. {remaining} attempt(s) remaining."
        )

    # OTP valid — generate a single-use reset token and clear the OTP
    reset_token = str(uuid.uuid4())
    reset_token_cache[reset_token] = payload.email
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
    payload: ChangePasswordRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)]
):
    """Change password for the currently authenticated user (validated schema)."""
    if not verify_password(payload.old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect.")

    current_user.hashed_password = hash_password(payload.new_password)
    session.add(current_user)
    session.commit()

    return {"message": "Password changed successfully."}
