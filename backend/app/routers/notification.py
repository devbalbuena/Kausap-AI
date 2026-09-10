from typing import Annotated, List, Optional
import uuid
import httpx
import logging
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from pydantic import BaseModel
from sqlmodel import Session, select, func
from app.database import get_session
from app.models.user import User, UserRole
from app.models.notification import Notification, NotificationType
from app.models.mood import MoodEntry
from app.models.chat import ChatMessage, ChatSession
from app.models.audit_log import AuditLog
from app.schemas.notification import NotificationRead
from app.core.deps import get_current_user
from app.core.config import settings

router = APIRouter(prefix="/notifications", tags=["Notifications"])

logger = logging.getLogger(__name__)


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


# ═══════════════════════════════════════════════════════════════════════════════
# 📅 MOOD CHECK-IN SCHEDULE — Save & Email Confirmation
# ═══════════════════════════════════════════════════════════════════════════════

class MoodScheduleRequest(BaseModel):
    morning_enabled: bool = True
    morning_time: str = "08:00"
    afternoon_enabled: bool = False
    afternoon_time: str = "14:00"
    evening_enabled: bool = True
    evening_time: str = "20:00"
    channel_push: bool = True
    channel_email: bool = False
    channel_inapp: bool = True


def _send_email_notification(to_email: str, to_name: str, schedule: MoodScheduleRequest) -> None:
    """
    Send a confirmation email via Brevo Transactional Email API.
    Gracefully no-ops if BREVO_API_KEY or BREVO_SENDER_EMAIL are not configured.
    Brevo API docs: https://developers.brevo.com/reference/sendtransacemail
    """
    if not settings.BREVO_API_KEY or not settings.BREVO_SENDER_EMAIL:
        logger.info("Brevo credentials not configured — skipping email notification.")
        return

    # ── Build schedule summary strings ──────────────────────────────────────
    slots = []
    if schedule.morning_enabled:
        h, m = schedule.morning_time.split(":")
        tod = "AM" if int(h) < 12 else "PM"
        h12 = int(h) % 12 or 12
        slots.append(f"🌅 Morning — {h12}:{m} {tod}")
    if schedule.afternoon_enabled:
        h, m = schedule.afternoon_time.split(":")
        tod = "AM" if int(h) < 12 else "PM"
        h12 = int(h) % 12 or 12
        slots.append(f"☀️ Afternoon — {h12}:{m} {tod}")
    if schedule.evening_enabled:
        h, m = schedule.evening_time.split(":")
        tod = "AM" if int(h) < 12 else "PM"
        h12 = int(h) % 12 or 12
        slots.append(f"🌙 Evening — {h12}:{m} {tod}")

    slots_html = "".join(
        f'<li style="margin:6px 0;color:#374151;">{s}</li>' for s in slots
    ) if slots else '<li style="color:#9CA3AF;">No check-ins scheduled</li>'

    channels = []
    if schedule.channel_push:
        channels.append("📱 Mobile & Browser Push")
    if schedule.channel_email:
        channels.append("📧 Email Notifications")
    if schedule.channel_inapp:
        channels.append("🔔 In-App Notification Bell")

    channels_html = "".join(
        f'<li style="margin:4px 0;color:#374151;">{c}</li>' for c in channels
    ) if channels else '<li style="color:#9CA3AF;">No channels enabled</li>'

    html_body = f"""
    <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:520px;margin:auto;background:#F9FAFB;border-radius:16px;overflow:hidden;border:1px solid #E5E7EB;">
      <div style="background:linear-gradient(135deg,#7C3AED,#6D28D9);padding:28px 32px;">
        <h1 style="margin:0;color:#fff;font-size:22px;">🧠 Kausap AI</h1>
        <p style="margin:6px 0 0;color:#DDD6FE;font-size:14px;">Your Mood Check-in Schedule is Set!</p>
      </div>
      <div style="padding:28px 32px;">
        <p style="color:#1F2937;font-size:15px;">Hi <strong>{to_name}</strong>,</p>
        <p style="color:#374151;font-size:14px;line-height:1.6;">
          Great news! Your personal wellness check-in schedule has been saved.
          Kausap AI will gently remind you to log your mood at the times you've chosen.
        </p>

        <div style="background:#EDE9FE;border-radius:12px;padding:16px 20px;margin:20px 0;">
          <p style="margin:0 0 10px;color:#4C1D95;font-size:13px;font-weight:700;text-transform:uppercase;letter-spacing:0.5px;">Your Check-in Times (Philippine Time)</p>
          <ul style="margin:0;padding-left:16px;">
            {slots_html}
          </ul>
        </div>

        <div style="background:#F0FDF4;border-radius:12px;padding:16px 20px;margin:20px 0;">
          <p style="margin:0 0 10px;color:#14532D;font-size:13px;font-weight:700;text-transform:uppercase;letter-spacing:0.5px;">Notification Channels</p>
          <ul style="margin:0;padding-left:16px;">
            {channels_html}
          </ul>
        </div>

        <p style="color:#6B7280;font-size:13px;line-height:1.6;">
          You can update your schedule anytime from <strong>Settings → Notifications</strong> in the Kausap AI app.
        </p>

        <div style="border-top:1px solid #E5E7EB;margin-top:24px;padding-top:16px;">
          <p style="color:#9CA3AF;font-size:12px;text-align:center;margin:0;">
            Kausap AI · Mental Health Companion · Philippine Standard Time (UTC+8)
          </p>
        </div>
      </div>
    </div>
    """

    # ── Send via Brevo Transactional Email API ───────────────────────────────
    payload = {
        "sender": {
            "name": settings.BREVO_SENDER_NAME,
            "email": settings.BREVO_SENDER_EMAIL,
        },
        "to": [{"email": to_email, "name": to_name}],
        "subject": "✅ Your Mood Check-in Schedule is Saved — Kausap AI",
        "htmlContent": html_body,
    }

    try:
        response = httpx.post(
            "https://api.brevo.com/v3/smtp/email",
            json=payload,
            headers={
                "accept": "application/json",
                "api-key": settings.BREVO_API_KEY,
                "content-type": "application/json",
            },
            timeout=15,
        )
        if response.status_code in (200, 201):
            logger.info(f"✅ Brevo: Schedule confirmation email sent to {to_email}")
        else:
            logger.warning(f"⚠️ Brevo API error {response.status_code}: {response.text}")
    except Exception as exc:
        logger.warning(f"⚠️ Failed to send Brevo email: {exc}")


@router.post("/schedule", status_code=200)
def save_mood_schedule(
    payload: MoodScheduleRequest,
    background_tasks: BackgroundTasks,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    Save the user's mood check-in schedule preferences.
    If email channel is enabled, sends a confirmation email in the background.
    """
    if payload.channel_email:
        background_tasks.add_task(
            _send_email_notification,
            current_user.email,
            current_user.first_name or "there",
            payload,
        )

    return {
        "saved": True,
        "morning": {"enabled": payload.morning_enabled, "time": payload.morning_time},
        "afternoon": {"enabled": payload.afternoon_enabled, "time": payload.afternoon_time},
        "evening": {"enabled": payload.evening_enabled, "time": payload.evening_time},
        "channels": {
            "push": payload.channel_push,
            "email": payload.channel_email,
            "inapp": payload.channel_inapp,
        },
        "email_queued": payload.channel_email,
        "message": "Schedule saved successfully. Email confirmation will arrive shortly." if payload.channel_email else "Schedule saved successfully.",
    }


@router.get("/guidance-notices", response_model=List[NotificationRead])
def get_guidance_notices(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Fetch official Guidance Call-Slip notices for the logged-in student."""
    notifs = session.exec(
        select(Notification)
        .where(
            Notification.user_id == current_user.id,
            Notification.type == NotificationType.guidance_notice,
            Notification.is_deleted == False,
        )
        .order_by(Notification.created_at.desc())
    ).all()
    return notifs


@router.post("/{notification_id}/acknowledge")
def acknowledge_guidance_notice(
    notification_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    Student confirms / acknowledges their physical Guidance Office consultation call slip.
    """
    notif = session.get(Notification, notification_id)
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")

    if notif.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to acknowledge this notice")

    notif.is_acknowledged = True
    notif.acknowledged_at = datetime.utcnow()
    notif.is_read = True
    session.add(notif)

    # Record acknowledgment in AuditLog
    audit = AuditLog(
        admin_id=current_user.id,
        admin_email=current_user.email,
        action="student_acknowledged_call_slip",
        target_type="notification",
        target_id=str(notification_id),
        detail=f"Student {current_user.full_name or current_user.email} acknowledged physical guidance consultation call-slip.",
    )
    session.add(audit)
    session.commit()

    return {
        "status": "acknowledged",
        "notification_id": str(notification_id),
        "acknowledged_at": notif.acknowledged_at.isoformat(),
        "message": "Visit successfully confirmed. The Guidance Counselor has been notified!",
    }
