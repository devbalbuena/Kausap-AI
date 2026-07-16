from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from app.database import get_session
from app.models.user import User, UserRole, ProfessionalProfile
from app.schemas.user import RegisterRequest, UserRead
from app.schemas.auth import Token, LoginRequest
from app.core.security import hash_password, verify_password, create_access_token
from app.core.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, session: Annotated[Session, Depends(get_session)]):
    """
    Register a new user account.
    - Role must be "client" or "professional" — "admin" is rejected with 400.
    - If role is "professional", a linked ProfessionalProfile is also created.
    """
    # Validate role (also caught by Pydantic validator, this is a belt-and-suspenders check)
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

    # Validate professional-specific fields
    if payload.role == UserRole.professional:
        missing = [f for f in ["profession", "prc_license_number", "specialization", "years_of_experience", "location"]
                   if getattr(payload, f) is None]
        if missing:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Professional registration requires these fields: {', '.join(missing)}"
            )

    # Create user
    user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        role=payload.role,
        first_name=payload.first_name,
        last_name=payload.last_name,
        phone_number=payload.phone_number,
        birthday=payload.birthday,
        gender=payload.gender,
        address=payload.address,
        bio=payload.bio,
        occupation=payload.occupation,
    )
    session.add(user)
    session.flush()  # Get user.id before committing

    # Create professional profile if needed
    if payload.role == UserRole.professional:
        profile = ProfessionalProfile(
            user_id=user.id,
            profession=payload.profession,
            prc_license_number=payload.prc_license_number,
            license_url=payload.license_url,
            specialization=payload.specialization,
            years_of_experience=payload.years_of_experience,
            bio=payload.professional_bio,
            is_accepting_clients=payload.is_accepting_clients if payload.is_accepting_clients is not None else True,
            location=payload.location,
            is_verified=False,  # always starts unverified
        )
        session.add(profile)

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
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is inactive")

    token = create_access_token(data={"sub": str(user.id), "role": user.role})
    return Token(access_token=token)


@router.get("/me", response_model=UserRead)
def me(current_user: Annotated[User, Depends(get_current_user)]):
    """Return the currently authenticated user's profile."""
    return current_user
