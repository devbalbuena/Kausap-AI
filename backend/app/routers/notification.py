from typing import Annotated, List
import uuid
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select, func
from app.database import get_session
from app.models.user import User
from app.models.notification import Notification, NotificationType
from app.schemas.notification import NotificationRead
from app.core.deps import get_current_user

from app.models.mood import MoodEntry

from app.models.user import User, UserRole
from app.models.chat import ChatMessage, ChatSession

router = APIRouter(prefix="/notifications", tags=["Notifications"])


def _ensure_daily_notifications(session: Session, user: User) -> List[Notification]:
    """
    Ensure the user receives fresh contextual notifications for today on app launch/sync.
    Timezone: Philippine / Singapore Standard Time (PHT / SGT, UTC+8).
    Supports both Student role (wellness & habits) and Counselor/Admin roles (clinical & triage alerts).
    """
    now_utc = datetime.utcnow()
    # Philippine / Singapore Standard Time (PHT / SGT, UTC+8)
    pht_now = now_utc + timedelta(hours=8)
    pht_today = pht_now.date()

    # UTC boundary for today in PHT (00:00:00 PHT = 16:00:00 UTC previous day)
    today_start_utc = datetime(pht_today.year, pht_today.month, pht_today.day) - timedelta(hours=8)

    # Check if user has received any notification today (in PHT calendar day)
    today_notifs = session.exec(
        select(Notification)
        .where(Notification.user_id == user.id, Notification.created_at >= today_start_utc)
    ).all()

    user_role_str = str(user.role.value if hasattr(user.role, 'value') else user.role).lower()

    if not today_notifs:
        if user_role_str in ['counselor', 'admin', 'superadmin']:
            # ══════════════════════════════════════════════════════════════════
            # 🛡️ COUNSELOR / ADMIN CLINICAL NOTIFICATIONS
            # ══════════════════════════════════════════════════════════════════

            # 1. Check for Unresolved Crisis Flags from Chat Messages
            unresolved_flags = session.exec(
                select(ChatMessage)
                .where(ChatMessage.risk_flag == True, ChatMessage.role == "user")  # noqa: E712
            ).all()

            for msg in unresolved_flags:
                chat_sess = session.get(ChatSession, msg.session_id)
                student_user = session.get(User, chat_sess.user_id) if chat_sess else None
                s_name = student_user.full_name or "Student" if student_user else "Student"
                session.add(Notification(
                    user_id=user.id,
                    title="🚨 Urgent Crisis Triage Alert",
                    body=f"High-risk safety escalation flagged in AI conversation for {s_name}. Immediate counselor triage review required.",
                    type=NotificationType.alert,
                    is_read=False,
                    created_at=msg.created_at or now_utc,
                ))

            # 2. Check for Consistent Distress Patterns (2+ consecutive low moods)
            students = session.exec(
                select(User)
                .where(User.role == UserRole.client, User.is_active == True, User.is_deleted == False)  # noqa: E712
            ).all()

            for s in students:
                entries = session.exec(
                    select(MoodEntry)
                    .where(MoodEntry.user_id == s.id)
                    .order_by(MoodEntry.created_at.desc())
                    .limit(7)
                ).all()

                consecutive_low = 0
                for entry in entries:
                    if entry.mood_level <= 2:
                        consecutive_low += 1
                    else:
                        break

                if consecutive_low >= 2:
                    s_name = s.full_name or s.email.split('@')[0]
                    session.add(Notification(
                        user_id=user.id,
                        title="⚠️ Consistent Distress Alert",
                        body=f"Early Intervention: {s_name} logged {consecutive_low} consecutive low moods. Guidance check-in recommended.",
                        type=NotificationType.alert,
                        is_read=False,
                        created_at=now_utc,
                    ))

            # 3. Check for Pending Reactivation Appeals
            appeals = session.exec(
                select(User)
                .where(User.is_active == False, User.reactivation_appeal != None, User.is_deleted == False)  # noqa: E711, E712
            ).all()

            for app_user in appeals:
                s_name = f"{app_user.first_name} {app_user.last_name}".strip() if hasattr(app_user, 'first_name') and app_user.first_name else (app_user.email.split('@')[0])
                appeal_text = (app_user.reactivation_appeal or '')[:60]
                session.add(Notification(
                    user_id=user.id,
                    title="📝 Student Reactivation Appeal",
                    body=f"Deactivated student {s_name} submitted an appeal: \"{appeal_text}...\"",
                    type=NotificationType.system,
                    is_read=False,
                    created_at=now_utc,
                ))

            # 4. Morning Campus Wellness Summary Digest
            total_students_count = len(students)
            total_moods_count = len(session.exec(select(MoodEntry)).all())
            session.add(Notification(
                user_id=user.id,
                title="📊 Daily Campus Wellness Pulse",
                body=f"FSUU Guidance Hub: {total_students_count} active students and {total_moods_count} total wellness check-ins on record.",
                type=NotificationType.message,
                is_read=False,
                created_at=now_utc,
            ))

            session.commit()

        else:
            # ══════════════════════════════════════════════════════════════════
            # 🌿 STUDENT WELLNESS & HABIT NOTIFICATIONS
            # ══════════════════════════════════════════════════════════════════
            today_mood = session.exec(
                select(MoodEntry)
                .where(MoodEntry.user_id == user.id, MoodEntry.created_at >= today_start_utc)
            ).first()

            recent_moods = session.exec(
                select(MoodEntry)
                .where(MoodEntry.user_id == user.id)
                .order_by(MoodEntry.created_at.desc())
                .limit(14)
            ).all()

            # Morning 7:00 AM PHT timestamp
            morning_7am_utc = today_start_utc + timedelta(hours=7)
            notif_time_1 = min(now_utc, morning_7am_utc)
            notif_time_2 = min(now_utc, morning_7am_utc + timedelta(minutes=15))
            notif_time_3 = min(now_utc, morning_7am_utc + timedelta(minutes=30))

            # 1. 7:00 AM Daily Wellness Check-in (if mood not yet logged today)
            if not today_mood:
                session.add(Notification(
                    user_id=user.id,
                    title="🌿 Daily Wellness Check-in",
                    body="☀️ Magandang umaga! How are you feeling today? Tap to record your mood in 1 tap.",
                    type=NotificationType.message,
                    is_read=False,
                    created_at=notif_time_1,
                ))

            # 2. 7:15 AM Daily Journal Reflection Prompt
            session.add(Notification(
                user_id=user.id,
                title="📖 Daily Journal Reflection",
                body="📝 Daily Journal Prompt: Take 2 minutes to write your thoughts or reflections for today.",
                type=NotificationType.system,
                is_read=False,
                created_at=notif_time_2,
            ))

            # 3. 7:30 AM Streak Milestone / Habit Tracker
            streak_count = len(recent_moods)
            if streak_count > 0:
                session.add(Notification(
                    user_id=user.id,
                    title="🔥 Streak Milestone!",
                    body=f"🔥 {streak_count}-Day Streak! You are maintaining great daily check-in habits.",
                    type=NotificationType.alert,
                    is_read=False,
                    created_at=notif_time_3,
                ))

            # 4. Multi-Day Distress Check-in
            consecutive_rough = 0
            for m in recent_moods:
                if m.mood_level <= 2:
                    consecutive_rough += 1
                else:
                    break
            if consecutive_rough >= 2:
                session.add(Notification(
                    user_id=user.id,
                    title="💙 Caring Guidance Support",
                    body="We noticed you've had a tough few days. You don't have to carry this alone. Tap here to chat with Kausap AI or connect with an FSUU counselor.",
                    type=NotificationType.alert,
                    is_read=False,
                    created_at=now_utc,
                ))

            session.commit()

    # Deduplicate existing notifications (keep newest unique per title & type per day)
    all_user_notifs = session.exec(
        select(Notification).where(Notification.user_id == user.id).order_by(Notification.created_at.desc())
    ).all()
    seen_keys = set()
    for n in all_user_notifs:
        key = (n.title, n.type, n.created_at.date())
        if key in seen_keys:
            session.delete(n)
        else:
            seen_keys.add(key)
    session.commit()

    return session.exec(
        select(Notification)
        .where(Notification.user_id == user.id, Notification.is_deleted == False)  # noqa: E712
        .order_by(Notification.created_at.desc())
    ).all()


@router.get("", response_model=List[NotificationRead])
@router.get("/", response_model=List[NotificationRead])
def get_notifications(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get all active notifications for the current user, generating today's notifications if needed."""
    return _ensure_daily_notifications(session, current_user)


@router.get("/unread-count")
@router.get("/unread-count/")
def get_unread_count(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get count of unread notifications for badge display."""
    _ensure_daily_notifications(session, current_user)

    unread = session.exec(
        select(Notification)
        .where(
            Notification.user_id == current_user.id,
            Notification.is_read == False,  # noqa: E712
            Notification.is_deleted == False,  # noqa: E712
        )
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
        .where(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
            Notification.is_deleted == False,  # noqa: E712
        )
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
    """Mark all active notifications as read."""
    unread = session.exec(
        select(Notification)
        .where(
            Notification.user_id == current_user.id,
            Notification.is_read == False,  # noqa: E712
            Notification.is_deleted == False,  # noqa: E712
        )
    ).all()
    for notif in unread:
        notif.is_read = True
        session.add(notif)
    session.commit()
    return {"marked_read": len(unread)}


@router.delete("/clear-all", status_code=200)
@router.delete("/clear-all/", status_code=200)
def clear_all_notifications(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Clear all notifications for the current user (soft delete)."""
    notifs = session.exec(
        select(Notification)
        .where(
            Notification.user_id == current_user.id,
            Notification.is_deleted == False,  # noqa: E712
        )
    ).all()
    count = len(notifs)
    for n in notifs:
        n.is_deleted = True
        session.add(n)
    session.commit()
    return {"cleared": count}


@router.delete("/{notification_id}", status_code=200)
@router.delete("/{notification_id}/", status_code=200)
def delete_notification(
    notification_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Delete a single notification (soft delete)."""
    notification = session.exec(
        select(Notification)
        .where(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
            Notification.is_deleted == False,  # noqa: E712
        )
    ).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    notification.is_deleted = True
    session.add(notification)
    session.commit()
    return {"deleted": True, "id": str(notification_id)}



