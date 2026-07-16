from typing import Annotated, List, Optional
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlmodel import Session, select, func

from app.database import get_session
from app.core.deps import get_current_admin
from app.models.user import User
from app.models.mood import MoodEntry
from app.models.chat import ChatSession, ChatMessage
from app.models.referral import DoctorReferral
from app.schemas.admin import UserSummary, FlaggedMessageRead, UserDetail, AdminStats

router = APIRouter(prefix="/admin", tags=["Admin"])


class StatusUpdate(BaseModel):
    is_active: bool


@router.get("/users", response_model=List[UserSummary])
def list_users(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
    email: Optional[str] = None,
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    """List users with optional email search and activity counts."""
    query = select(User)
    if email:
        query = query.where(User.email.contains(email))
    query = query.order_by(User.created_at.desc()).offset(offset).limit(limit)
    
    users = session.exec(query).all()
    
    summaries = []
    for u in users:
        # Count moods
        mood_count = session.exec(select(func.count()).select_from(MoodEntry).where(MoodEntry.user_id == u.id)).one()
        # Count chat sessions
        chat_count = session.exec(select(func.count()).select_from(ChatSession).where(ChatSession.user_id == u.id)).one()
        
        summaries.append(
            UserSummary(
                id=u.id,
                email=u.email,
                full_name=u.full_name,
                role=u.role,
                is_active=u.is_active,
                created_at=u.created_at,
                mood_entries_count=mood_count,
                chat_sessions_count=chat_count,
            )
        )
    return summaries


@router.get("/users/{user_id}", response_model=UserDetail)
def get_user_detail(
    user_id: uuid.UUID,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get full details on a specific user, including recent activity."""
    u = session.get(User, user_id)
    if not u:
        raise HTTPException(status_code=404, detail="User not found")

    recent_moods = session.exec(select(MoodEntry).where(MoodEntry.user_id == u.id).order_by(MoodEntry.created_at.desc()).limit(10)).all()
    recent_sessions = session.exec(select(ChatSession).where(ChatSession.user_id == u.id).order_by(ChatSession.created_at.desc()).limit(10)).all()
    referrals = session.exec(select(DoctorReferral).where(DoctorReferral.user_id == u.id).order_by(DoctorReferral.created_at.desc())).all()

    return UserDetail(
        id=u.id,
        email=u.email,
        full_name=u.full_name,
        role=u.role,
        is_active=u.is_active,
        created_at=u.created_at,
        recent_moods=recent_moods,
        recent_sessions=recent_sessions,
        referrals=referrals,
    )


@router.patch("/users/{user_id}/status")
def update_user_status(
    user_id: uuid.UUID,
    payload: StatusUpdate,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Deactivate or reactivate a user account."""
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Cannot deactivate your own admin account")
        
    u = session.get(User, user_id)
    if not u:
        raise HTTPException(status_code=404, detail="User not found")
        
    u.is_active = payload.is_active
    session.add(u)
    session.commit()
    return {"id": u.id, "is_active": u.is_active}


@router.get("/flagged-messages", response_model=List[FlaggedMessageRead])
def list_flagged_messages(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    """List all risk-flagged messages joined with user info."""
    # Join ChatMessage -> ChatSession -> User
    query = (
        select(ChatMessage, ChatSession, User)
        .join(ChatSession, ChatMessage.session_id == ChatSession.id)
        .join(User, ChatSession.user_id == User.id)
        .where(ChatMessage.risk_flag == True)
        .order_by(ChatMessage.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    results = session.exec(query).all()
    
    flagged = []
    for msg, chat_session, user in results:
        flagged.append(
            FlaggedMessageRead(
                id=msg.id,
                session_id=chat_session.id,
                user_id=user.id,
                user_email=user.email,
                role=msg.role,
                content=msg.content,
                created_at=msg.created_at
            )
        )
    return flagged


@router.get("/stats", response_model=AdminStats)
def admin_stats(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get system-wide metrics for the dashboard."""
    total_users = session.exec(select(func.count()).select_from(User)).one()
    total_active = session.exec(select(func.count()).select_from(User).where(User.is_active == True)).one()
    total_moods = session.exec(select(func.count()).select_from(MoodEntry)).one()
    total_sessions = session.exec(select(func.count()).select_from(ChatSession)).one()
    total_flagged = session.exec(select(func.count()).select_from(ChatMessage).where(ChatMessage.risk_flag == True)).one()
    total_referrals = session.exec(select(func.count()).select_from(DoctorReferral)).one()
    
    return AdminStats(
        total_users=total_users,
        total_active_users=total_active,
        total_mood_entries=total_moods,
        total_chat_sessions=total_sessions,
        total_flagged_messages=total_flagged,
        total_referrals=total_referrals,
    )
