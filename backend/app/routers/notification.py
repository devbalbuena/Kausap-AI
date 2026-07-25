from typing import Annotated, List
import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.database import get_session
from app.models.user import User
from app.models.notification import Notification
from app.schemas.notification import NotificationRead
from app.core.deps import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=List[NotificationRead])
def get_notifications(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get all notifications for the current user, newest first."""
    notifications = session.exec(
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
    ).all()
    return notifications


@router.get("/unread-count")
def get_unread_count(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get count of unread notifications for badge display."""
    unread = session.exec(
        select(Notification)
        .where(Notification.user_id == current_user.id, Notification.is_read == False)  # noqa: E712
    ).all()
    return {"count": len(unread)}


@router.put("/{notification_id}/read", response_model=NotificationRead)
def mark_as_read(
    notification_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Mark a single notification as read."""
    notification = session.exec(
        select(Notification)
        .where(Notification.id == notification_id, Notification.user_id == current_user.id)
    ).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    notification.is_read = True
    session.add(notification)
    session.commit()
    session.refresh(notification)
    return notification


@router.put("/read-all")
def mark_all_as_read(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Mark all notifications as read."""
    unread = session.exec(
        select(Notification)
        .where(Notification.user_id == current_user.id, Notification.is_read == False)  # noqa: E712
    ).all()
    for notif in unread:
        notif.is_read = True
        session.add(notif)
    session.commit()
    return {"marked_read": len(unread)}
