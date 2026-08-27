from typing import Annotated, List
import uuid
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.database import get_session
from app.models.user import User
from app.models.notification import Notification, NotificationType
from app.schemas.notification import NotificationRead
from app.core.deps import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications"])


def _seed_initial_notifications_if_empty(session: Session, user: User) -> List[Notification]:
    """Seed initial helpful wellness notifications if user has none."""
    existing = session.exec(select(Notification).where(Notification.user_id == user.id)).all()
    if existing:
        return existing

    now = datetime.utcnow()
    defaults = [
        Notification(
            user_id=user.id,
            title="🌿 Daily Wellness Check-in",
            body="How are you feeling today? Tap to record your mood in 1 tap.",
            type=NotificationType.message,
            is_read=False,
            created_at=now - timedelta(minutes=4),
        ),
        Notification(
            user_id=user.id,
            title="🔥 Streak Milestone!",
            body="You are maintaining your consistency! Keep up your daily check-in habits.",
            type=NotificationType.alert,
            is_read=False,
            created_at=now - timedelta(minutes=28),
        ),
        Notification(
            user_id=user.id,
            title="📋 Clinical Self-Assessment Ready",
            body="Take a quick 2-minute PHQ-9 or GAD-7 screener to gain deep emotional insights.",
            type=NotificationType.session,
            is_read=False,
            created_at=now - timedelta(hours=1, minutes=20),
        ),
        Notification(
            user_id=user.id,
            title="📖 Evening Reflection",
            body="Take a few minutes to write or voice record your thoughts in your Daily Journal.",
            type=NotificationType.system,
            is_read=True,
            created_at=now - timedelta(hours=3, minutes=45),
        ),
    ]
    for d in defaults:
        session.add(d)
    session.commit()
    return session.exec(select(Notification).where(Notification.user_id == user.id).order_by(Notification.created_at.desc())).all()


@router.get("", response_model=List[NotificationRead])
@router.get("/", response_model=List[NotificationRead])
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

    if not notifications:
        notifications = _seed_initial_notifications_if_empty(session, current_user)

    return notifications


@router.get("/unread-count")
@router.get("/unread-count/")
def get_unread_count(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get count of unread notifications for badge display."""
    unread = session.exec(
        select(Notification)
        .where(Notification.user_id == current_user.id, Notification.is_read == False)  # noqa: E712
    ).all()

    if not unread:
        # Check if user has zero notifications at all; if so, seed defaults
        total = session.exec(select(Notification).where(Notification.user_id == current_user.id)).all()
        if not total:
            _seed_initial_notifications_if_empty(session, current_user)
            unread = session.exec(
                select(Notification)
                .where(Notification.user_id == current_user.id, Notification.is_read == False)
            ).all()

    return {"count": len(unread)}


@router.put("/{notification_id}/read", response_model=NotificationRead)
@router.put("/{notification_id}/read/", response_model=NotificationRead)
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
@router.put("/read-all/")
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
