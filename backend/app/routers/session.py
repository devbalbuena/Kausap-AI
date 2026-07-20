from typing import Annotated, List
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from app.database import get_session
from app.core.deps import get_current_user
from app.models.user import User
from app.models.session import TherapySession, SessionStatus
from app.schemas.session import TherapySessionCreate, TherapySessionRead
from datetime import datetime

router = APIRouter(prefix="/sessions", tags=["Sessions"])

@router.post("", response_model=TherapySessionRead, status_code=status.HTTP_201_CREATED)
def book_session(
    payload: TherapySessionCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """Book a new therapy session."""
    if current_user.role != "client":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only clients can book sessions")
        
    # Check for conflicts: target professional already has a scheduled session at that exact date_time
    conflict = db.exec(
        select(TherapySession)
        .where(TherapySession.professional_id == payload.professional_id)
        .where(TherapySession.date_time == payload.date_time)
        .where(TherapySession.status == SessionStatus.SCHEDULED)
    ).first()
    
    if conflict:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="The professional is already booked for this specific time slot."
        )

    session_obj = TherapySession(
        client_id=current_user.id,
        professional_id=payload.professional_id,
        date_time=payload.date_time,
        reason=payload.reason,
        mode=payload.mode,
        notes=payload.notes,
        status=SessionStatus.SCHEDULED
    )
    
    db.add(session_obj)
    db.commit()
    db.refresh(session_obj)
    return session_obj

@router.get("/upcoming", response_model=List[TherapySessionRead])
def get_upcoming_sessions(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """Get upcoming scheduled sessions for the current client."""
    return db.exec(
        select(TherapySession)
        .where(TherapySession.client_id == current_user.id)
        .where(TherapySession.status == SessionStatus.SCHEDULED)
        .where(TherapySession.date_time >= datetime.utcnow())
        .order_by(TherapySession.date_time.asc())
    ).all()

@router.get("/past", response_model=List[TherapySessionRead])
def get_past_sessions(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """Get past completed or cancelled sessions for the current client."""
    return db.exec(
        select(TherapySession)
        .where(TherapySession.client_id == current_user.id)
        .where((TherapySession.status == SessionStatus.COMPLETED) | 
               (TherapySession.status == SessionStatus.CANCELLED) |
               ((TherapySession.status == SessionStatus.SCHEDULED) & (TherapySession.date_time < datetime.utcnow())))
        .order_by(TherapySession.date_time.desc())
    ).all()
