from typing import Annotated, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlmodel import Session, select
from app.database import get_session
from app.core.security import decode_access_token
from app.models.user import User

bearer_scheme = HTTPBearer()
bearer_scheme_optional = HTTPBearer(auto_error=False)


def get_current_user_allow_inactive(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer_scheme)],
    session: Annotated[Session, Depends(get_session)],
) -> User:
    """Decode the JWT and return user (even if deactivated, as long as not soft deleted)."""
    token = credentials.credentials
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id: str = payload.get("sub")
    if user_id is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")

    user = session.get(User, user_id)
    if user is None or user.is_deleted:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or archived")
    return user


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer_scheme)],
    session: Annotated[Session, Depends(get_session)],
) -> User:
    """Decode the JWT and return active authenticated user."""
    user = get_current_user_allow_inactive(credentials, session)
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is deactivated")
    return user


def get_current_user_optional(
    credentials: Annotated[Optional[HTTPAuthorizationCredentials], Depends(bearer_scheme_optional)],
    session: Annotated[Session, Depends(get_session)],
) -> Optional[User]:
    """Decode the JWT if present and return the user, or None if anonymous/invalid."""
    if not credentials:
        return None
    token = credentials.credentials
    payload = decode_access_token(token)
    if not payload:
        return None
    user_id = payload.get("sub")
    if not user_id:
        return None
    return session.get(User, user_id)


def get_current_admin(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Same as get_current_user but also enforces admin role. Raises 403 otherwise."""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return current_user
