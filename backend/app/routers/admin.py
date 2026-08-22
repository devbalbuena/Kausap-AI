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
from app.schemas.admin import UserSummary, FlaggedMessageRead, UserDetail, AdminStats

router = APIRouter(prefix="/admin", tags=["Admin"])


class StatusUpdate(BaseModel):
    is_active: bool


@router.get("/users", response_model=List[UserSummary])
def list_users(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
    email: Optional[str] = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
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
        # Count flagged messages
        flag_count = session.exec(
            select(func.count())
            .select_from(ChatMessage)
            .join(ChatSession, ChatMessage.session_id == ChatSession.id)
            .where(ChatSession.user_id == u.id)
            .where(ChatMessage.risk_flag == True)
        ).one()
        
        summaries.append(
            UserSummary(
                id=u.id,
                email=u.email,
                full_name=f"{u.first_name} {u.last_name}".strip(),
                role=u.role,
                is_active=u.is_active,
                created_at=u.created_at,
                mood_entries_count=mood_count,
                chat_sessions_count=chat_count,
                flagged_messages_count=flag_count,
                phone_number=u.phone_number,
                birthday=str(u.birthday) if u.birthday else None,
                gender=u.gender.value if u.gender else None,
                occupation=u.occupation.value if u.occupation else None,
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

    return UserDetail(
        id=u.id,
        email=u.email,
        full_name=f"{u.first_name} {u.last_name}".strip(),
        role=u.role,
        is_active=u.is_active,
        created_at=u.created_at,
        phone_number=u.phone_number,
        birthday=str(u.birthday) if u.birthday else None,
        gender=u.gender.value if u.gender else None,
        occupation=u.occupation.value if u.occupation else None,
        recent_moods=recent_moods,
        recent_sessions=recent_sessions,
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


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: uuid.UUID,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Permanently delete a user and cascade their data."""
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Cannot delete your own admin account")
        
    u = session.get(User, user_id)
    if not u:
        raise HTTPException(status_code=404, detail="User not found")

    session.delete(u)
    session.commit()
    return None


@router.get("/flagged-messages", response_model=List[FlaggedMessageRead])
def list_flagged_messages(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
):
    """List all risk-flagged messages joined with user info."""
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


@router.patch("/flagged-messages/{message_id}/resolve")
def resolve_flagged_message(
    message_id: uuid.UUID,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Mark a specific flagged message incident as resolved."""
    msg = session.get(ChatMessage, message_id)
    if not msg:
        raise HTTPException(status_code=404, detail="Flagged message not found")
    
    msg.risk_flag = False
    session.add(msg)
    session.commit()
    return {"status": "resolved", "id": str(message_id)}


@router.post("/flagged-messages/resolve-all")
def resolve_all_flagged_messages(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Mark all active crisis flagged messages as resolved."""
    messages = session.exec(select(ChatMessage).where(ChatMessage.risk_flag == True)).all()
    count = len(messages)
    for m in messages:
        m.risk_flag = False
        session.add(m)
    session.commit()
    return {"status": "all_resolved", "resolved_count": count}


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

    # Mood level breakdown (1 to 5)
    mood_counts = {
        "great": session.exec(select(func.count()).select_from(MoodEntry).where(MoodEntry.mood_level == 5)).one(),
        "good": session.exec(select(func.count()).select_from(MoodEntry).where(MoodEntry.mood_level == 4)).one(),
        "okay": session.exec(select(func.count()).select_from(MoodEntry).where(MoodEntry.mood_level == 3)).one(),
        "down": session.exec(select(func.count()).select_from(MoodEntry).where(MoodEntry.mood_level == 2)).one(),
        "distressed": session.exec(select(func.count()).select_from(MoodEntry).where(MoodEntry.mood_level == 1)).one(),
    }
    
    return AdminStats(
        total_users=total_users,
        total_active_users=total_active,
        total_mood_entries=total_moods,
        total_chat_sessions=total_sessions,
        total_flagged_messages=total_flagged,
        mood_distribution=mood_counts,
    )
