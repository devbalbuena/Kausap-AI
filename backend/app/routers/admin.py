from datetime import datetime, timezone, timedelta
from typing import Annotated, List, Optional, Dict, Any
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlmodel import Session, select, func

from app.database import get_session, engine
from app.core.deps import get_current_admin, get_current_counselor_or_admin
from app.core.security import get_password_hash
from app.models.user import User, UserRole, GenderEnum
from app.models.mood import MoodEntry
from app.models.chat import ChatSession, ChatMessage
from app.models.audit_log import AuditLog
from app.models.token_log import TokenUsageLog
from app.schemas.admin import (
    UserSummary, FlaggedMessageRead, UserDetail, AdminStats,
    CounselorCreate, CounselorRead, CounselorStatusUpdate, CounselorPasswordReset,
    TokenTelemetrySummary, DailyTokenPoint, SystemHealthTelemetry, DistressPatternAlert,
)
from app.schemas.audit import AuditLogRead

router = APIRouter(prefix="/admin", tags=["Admin"])


def _write_audit(
    db: Session,
    admin: User,
    action: str,
    target_type: str,
    target_id: str,
    detail: Optional[str] = None,
) -> None:
    """Append an immutable audit log entry after every sensitive counselor action."""
    entry = AuditLog(
        admin_id=admin.id,
        admin_email=admin.email,
        action=action,
        target_type=target_type,
        target_id=str(target_id),
        detail=detail,
    )
    db.add(entry)
    db.commit()


class StatusUpdate(BaseModel):
    is_active: bool
    deactivation_reason: Optional[str] = None


@router.get("/users", response_model=List[UserSummary])
def list_users(
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
    email: Optional[str] = None,
    include_deleted: bool = True,
    limit: Annotated[int, Query(ge=1, le=200)] = 200,
    offset: Annotated[int, Query(ge=0)] = 0,
):
    """List users with optional email search, deactivation status, and activity counts."""
    query = select(User)
    if email:
        query = query.where(User.email.contains(email))
    if not include_deleted:
        query = query.where(User.is_deleted == False)
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
                is_deleted=u.is_deleted,
                deleted_at=u.deleted_at,
                deactivated_at=u.deactivated_at,
                deactivation_reason=u.deactivation_reason,
                reactivation_appeal=u.reactivation_appeal,
                reactivation_appeal_at=u.reactivation_appeal_at,
                created_at=u.created_at,
                mood_entries_count=mood_count,
                chat_sessions_count=chat_count,
                flagged_messages_count=flag_count,
                phone_number=u.phone_number,
                birthday=str(u.birthday) if u.birthday else None,
                gender=u.gender.value if u.gender else None,
                occupation=u.occupation.value if hasattr(u.occupation, 'value') else (str(u.occupation) if u.occupation else None),
                nationality=getattr(u, 'nationality', 'Filipino') or 'Filipino',
                hobbies=getattr(u, 'hobbies', None),
            )
        )
    return summaries


@router.get("/users/{user_id}", response_model=UserDetail)
def get_user_detail(
    user_id: uuid.UUID,
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
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
        is_deleted=u.is_deleted,
        deleted_at=u.deleted_at,
        deactivated_at=u.deactivated_at,
        deactivation_reason=u.deactivation_reason,
        reactivation_appeal=u.reactivation_appeal,
        reactivation_appeal_at=u.reactivation_appeal_at,
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
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Deactivate or reactivate a user account with optional counselor reason."""
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Cannot deactivate your own account")

    u = session.get(User, user_id)
    if not u:
        raise HTTPException(status_code=404, detail="User not found")

    u.is_active = payload.is_active
    if not payload.is_active:
        u.deactivated_at = datetime.utcnow()
        u.deactivation_reason = payload.deactivation_reason or "Account temporarily deactivated by University Guidance Office."
        action = "user_deactivated"
    else:
        u.deactivated_at = None
        u.deactivation_reason = None
        u.reactivation_appeal = None
        u.reactivation_appeal_at = None
        action = "user_reactivated"

    session.add(u)
    session.commit()
    session.refresh(u)

    _write_audit(
        session, admin, action, "user", str(user_id),
        detail=payload.deactivation_reason or ("Reactivated by counselor" if payload.is_active else None),
    )

    return {
        "id": u.id,
        "is_active": u.is_active,
        "deactivation_reason": u.deactivation_reason,
        "deactivated_at": u.deactivated_at,
    }


@router.delete("/users/{user_id}")
def delete_user(
    user_id: uuid.UUID,
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Soft delete a user account in compliance with RA 11036 (preserves records)."""
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Cannot delete your own account")

    u = session.get(User, user_id)
    if not u:
        raise HTTPException(status_code=404, detail="User not found")

    u.is_deleted = True
    u.deleted_at = datetime.utcnow()
    u.is_active = False
    session.add(u)
    session.commit()

    _write_audit(session, admin, "user_archived", "user", str(user_id),
                 detail=f"Soft-deleted: {u.email} — RA 11036 compliant archive.")

    return {"message": f"User {u.email} has been safely archived (soft deleted).", "id": u.id}


@router.post("/users/{user_id}/restore")
def restore_user(
    user_id: uuid.UUID,
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Restore a soft-deleted user account."""
    u = session.get(User, user_id)
    if not u:
        raise HTTPException(status_code=404, detail="User not found")

    u.is_deleted = False
    u.deleted_at = None
    u.is_active = True
    u.deactivation_reason = None
    u.deactivated_at = None
    u.reactivation_appeal = None
    u.reactivation_appeal_at = None
    session.add(u)
    session.commit()
    session.refresh(u)

    _write_audit(session, admin, "user_restored", "user", str(user_id),
                 detail=f"Account fully restored: {u.email}")

    return {"message": f"User {u.email} has been fully restored.", "id": u.id, "is_active": u.is_active}


@router.post("/users/{user_id}/resolve-appeal")
def resolve_appeal(
    user_id: uuid.UUID,
    approved: bool,
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Approve or dismiss a student's reactivation appeal."""
    u = session.get(User, user_id)
    if not u:
        raise HTTPException(status_code=404, detail="User not found")

    if approved:
        u.is_active = True
        u.deactivation_reason = None
        u.deactivated_at = None
        u.reactivation_appeal = None
        u.reactivation_appeal_at = None
        action = "appeal_approved"
        detail = f"Reactivation appeal approved for {u.email}"
    else:
        # Dismiss appeal, keep deactivated
        u.reactivation_appeal = None
        u.reactivation_appeal_at = None
        action = "appeal_dismissed"
        detail = f"Reactivation appeal dismissed for {u.email}"

    session.add(u)
    session.commit()
    session.refresh(u)

    _write_audit(session, admin, action, "user", str(user_id), detail=detail)

    return {"message": "Appeal processed successfully.", "id": u.id, "is_active": u.is_active}


@router.get("/flagged-messages", response_model=List[FlaggedMessageRead])
@router.get("/flagged-messages/", response_model=List[FlaggedMessageRead])
def list_flagged_messages(
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
):
    """List all risk-flagged messages (both active and resolved) joined with user info."""
    # 1. Fetch active flagged messages (risk_flag == True and role == 'user')
    active_query = (
        select(ChatMessage, ChatSession, User)
        .join(ChatSession, ChatMessage.session_id == ChatSession.id)
        .join(User, ChatSession.user_id == User.id)
        .where(ChatMessage.risk_flag == True, ChatMessage.role == "user")
        .order_by(ChatMessage.created_at.desc())
    )
    active_results = session.exec(active_query).all()
    
    flagged = []
    seen_ids = set()
    for msg, chat_session, user in active_results:
        seen_ids.add(msg.id)
        flagged.append(
            FlaggedMessageRead(
                id=msg.id,
                session_id=chat_session.id,
                user_id=user.id,
                user_email=user.email,
                user_name=user.full_name or user.email.split('@')[0],
                role=msg.role,
                content=msg.content,
                created_at=msg.created_at,
                is_resolved=False,
            )
        )
    
    # 2. Fetch resolved triage audit logs (action == "resolve_flag", target_type == "message")
    audit_query = (
        select(AuditLog)
        .where(AuditLog.action == "resolve_flag", AuditLog.target_type == "message")
        .order_by(AuditLog.created_at.desc())
        .limit(limit)
    )
    resolved_audits = session.exec(audit_query).all()

    for audit in resolved_audits:
        try:
            msg_uuid = uuid.UUID(audit.target_id)
            if msg_uuid in seen_ids:
                continue
            seen_ids.add(msg_uuid)
            msg = session.get(ChatMessage, msg_uuid)
            if msg:
                chat_session = session.get(ChatSession, msg.session_id)
                user = session.get(User, chat_session.user_id) if chat_session else None
                flagged.append(
                    FlaggedMessageRead(
                        id=msg.id,
                        session_id=msg.session_id,
                        user_id=user.id if user else audit.admin_id,
                        user_email=user.email if user else "student@urios.edu.ph",
                        user_name=user.full_name if user else "Student",
                        role=msg.role,
                        content=msg.content,
                        created_at=msg.created_at,
                        is_resolved=True,
                        resolved_at=audit.created_at,
                        resolution_note=audit.detail or "Resolved by counselor",
                        flag_reason="Crisis Trigger Resolved",
                        risk_level="red",
                    )
                )
        except Exception:
            continue

    # 3. Include active distress pattern alerts (2-day Yellow and 3-day Red)
    distress_alerts = get_consistent_distress_patterns(admin=admin, session=session)
    for da in distress_alerts:
        distress_id = uuid.uuid5(uuid.NAMESPACE_DNS, f"distress_{da.user_id}_{da.consecutive_days}")
        if distress_id in seen_ids:
            continue
        seen_ids.add(distress_id)

        is_red = da.risk_level == "red"
        reason_text = f"{da.consecutive_days}-Day Persistent Distress Alert" if is_red else f"{da.consecutive_days}-Day Low Mood Trend"
        excerpt = f"Student has logged {da.consecutive_days} consecutive days of rough/low mood (Latest: {da.latest_mood_label} - Level {da.latest_mood_level}/5)."
        if da.latest_note:
            excerpt += f' Note: "{da.latest_note}"'

        flagged.append(
            FlaggedMessageRead(
                id=distress_id,
                session_id=None,
                user_id=da.user_id,
                user_email=da.email,
                user_name=da.full_name,
                role="user",
                content=excerpt,
                created_at=datetime.utcnow(),
                is_resolved=False,
                flag_reason=reason_text,
                risk_level=da.risk_level,
            )
        )

    return flagged


@router.patch("/flagged-messages/{message_id}/resolve")
@router.patch("/flagged-messages/{message_id}/resolve/")
def resolve_flagged_message(
    message_id: uuid.UUID,
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
    payload: Optional[Dict[str, Any]] = None,
):
    """Mark a specific flagged message incident as resolved and record in AuditLog."""
    msg = session.get(ChatMessage, message_id)
    if not msg:
        raise HTTPException(status_code=404, detail="Flagged message not found")
    
    msg.risk_flag = False
    session.add(msg)
    
    note = (payload or {}).get("resolution_note") or f"Crisis triage resolved by {admin.email}."
    audit = AuditLog(
        admin_id=admin.id,
        admin_email=admin.email,
        action="resolve_flag",
        target_type="message",
        target_id=str(message_id),
        detail=note,
    )
    session.add(audit)
    session.commit()
    return {"status": "resolved", "id": str(message_id)}


@router.post("/flagged-messages/resolve-all")
@router.post("/flagged-messages/resolve-all/")
def resolve_all_flagged_messages(
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Mark all active crisis flagged messages as resolved."""
    messages = session.exec(select(ChatMessage).where(ChatMessage.risk_flag == True)).all()
    count = len(messages)
    for m in messages:
        m.risk_flag = False
        session.add(m)
        audit = AuditLog(
            admin_id=admin.id,
            admin_email=admin.email,
            action="resolve_flag",
            target_type="message",
            target_id=str(m.id),
            detail="Batch crisis triage resolution completed.",
        )
        session.add(audit)
    session.commit()
    return {"status": "all_resolved", "resolved_count": count}


@router.get("/stats", response_model=AdminStats)
def admin_stats(
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get system-wide metrics for the dashboard."""
    total_users = session.exec(select(func.count()).select_from(User)).one()
    total_active = session.exec(select(func.count()).select_from(User).where(User.is_active == True)).one()
    total_students = session.exec(select(func.count()).select_from(User).where(User.role == UserRole.client)).one()
    total_active_students = session.exec(select(func.count()).select_from(User).where(User.role == UserRole.client, User.is_active == True)).one()
    total_moods = session.exec(select(func.count()).select_from(MoodEntry)).one()
    total_sessions = session.exec(select(func.count()).select_from(ChatSession)).one()
    total_flagged = session.exec(select(func.count()).select_from(ChatMessage).where(ChatMessage.risk_flag == True, ChatMessage.role == "user")).one()
    total_counselors = session.exec(select(func.count()).select_from(User).where(User.role == UserRole.counselor)).one()

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
        total_students=total_students,
        total_active_students=total_active_students,
        total_mood_entries=total_moods,
        total_chat_sessions=total_sessions,
        total_flagged_messages=total_flagged,
        total_counselors=total_counselors,
        mood_distribution=mood_counts,
    )


@router.get("/audit-logs", response_model=List[AuditLogRead])
def list_audit_logs(
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
    action: Optional[str] = None,
    target_type: Optional[str] = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
):
    """Paginated, filterable admin audit log. Newest entries first."""
    query = select(AuditLog)
    if action:
        query = query.where(AuditLog.action == action)
    if target_type:
        query = query.where(AuditLog.target_type == target_type)
    query = query.order_by(AuditLog.created_at.desc()).offset(offset).limit(limit)
    return session.exec(query).all()


# ── Super Admin: Counselor Workforce Provisioning ───────────────────────────

@router.get("/counselors", response_model=List[CounselorRead])
def list_counselors(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """List all registered university guidance counselors (Super Admin only)."""
    counselors = session.exec(
        select(User)
        .where(User.role == UserRole.counselor)
        .order_by(User.created_at.desc())
    ).all()

    return [
        CounselorRead(
            id=c.id,
            email=c.email,
            full_name=c.full_name,
            role=c.role.value if hasattr(c.role, "value") else str(c.role),
            department_title=c.department_title or "Guidance Counselor",
            phone_number=c.phone_number,
            gender=c.gender.value if hasattr(c.gender, "value") else str(c.gender),
            is_active=c.is_active,
            created_at=c.created_at,
        )
        for c in counselors
    ]


@router.post("/counselors", response_model=CounselorRead, status_code=status.HTTP_201_CREATED)
def create_counselor(
    payload: CounselorCreate,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Provision a new verified Guidance Counselor account (Super Admin only)."""
    # Check if email already registered
    existing = session.exec(select(User).where(User.email == payload.email)).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"An account with email '{payload.email}' already exists.",
        )

    # Validate gender
    gender_enum = GenderEnum.female
    try:
        if payload.gender:
            gender_enum = GenderEnum(payload.gender)
    except Exception:
        gender_enum = GenderEnum.female

    new_counselor = User(
        id=uuid.uuid4(),
        email=payload.email.strip().lower(),
        hashed_password=get_password_hash(payload.password),
        role=UserRole.counselor,
        first_name=payload.first_name.strip(),
        last_name=payload.last_name.strip(),
        phone_number=payload.phone_number.strip(),
        department_title=payload.department_title.strip() if payload.department_title else "Guidance Counselor",
        birthday=datetime(1990, 1, 1).date(),
        gender=gender_enum,
        is_active=True,
        is_deleted=False,
    )
    session.add(new_counselor)
    session.commit()
    session.refresh(new_counselor)

    _write_audit(
        session,
        admin,
        "counselor_created",
        "user",
        str(new_counselor.id),
        detail=f"Provisioned verified counselor account: {new_counselor.email} ({new_counselor.department_title})",
    )

    return CounselorRead(
        id=new_counselor.id,
        email=new_counselor.email,
        full_name=new_counselor.full_name,
        role=new_counselor.role.value if hasattr(new_counselor.role, "value") else str(new_counselor.role),
        department_title=new_counselor.department_title,
        phone_number=new_counselor.phone_number,
        gender=new_counselor.gender.value if hasattr(new_counselor.gender, "value") else str(new_counselor.gender),
        is_active=new_counselor.is_active,
        created_at=new_counselor.created_at,
    )


@router.patch("/counselors/{counselor_id}/status")
def update_counselor_status(
    counselor_id: uuid.UUID,
    payload: CounselorStatusUpdate,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Activate or deactivate a Counselor account (Super Admin only)."""
    counselor = session.get(User, counselor_id)
    if not counselor or counselor.role != UserRole.counselor:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Counselor not found")

    counselor.is_active = payload.is_active
    session.add(counselor)
    session.commit()
    session.refresh(counselor)

    action = "counselor_activated" if payload.is_active else "counselor_deactivated"
    _write_audit(
        session,
        admin,
        action,
        "user",
        str(counselor.id),
        detail=f"Counselor {counselor.email} status changed to {'active' if payload.is_active else 'inactive'}",
    )

    return {"id": counselor.id, "email": counselor.email, "is_active": counselor.is_active}


@router.post("/counselors/{counselor_id}/reset-password")
def reset_counselor_password(
    counselor_id: uuid.UUID,
    payload: CounselorPasswordReset,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Reset a Counselor's password (Super Admin only)."""
    counselor = session.get(User, counselor_id)
    if not counselor or counselor.role != UserRole.counselor:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Counselor not found")

    counselor.hashed_password = get_password_hash(payload.new_password)
    session.add(counselor)
    session.commit()

    _write_audit(
        session,
        admin,
        "counselor_password_reset",
        "user",
        str(counselor.id),
        detail=f"Temporary password reset issued for counselor: {counselor.email}",
    )

    return {"message": f"Password reset successfully for {counselor.email}"}


# ── Super Admin: AI Token & Cost Telemetry ───────────────────────────────────

@router.get("/telemetry/tokens", response_model=TokenTelemetrySummary)
def get_token_telemetry(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get aggregated OpenAI token metrics and estimated costs (Super Admin only)."""
    logs = session.exec(select(TokenUsageLog).order_by(TokenUsageLog.created_at.desc())).all()

    total_prompt = sum(l.prompt_tokens for l in logs)
    total_completion = sum(l.completion_tokens for l in logs)
    total_tokens = sum(l.total_tokens for l in logs)
    total_cost_usd = sum(l.estimated_cost_usd for l in logs)
    total_cost_php = total_cost_usd * 57.50

    # Today's tokens
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    today_logs = [l for l in logs if l.created_at >= today_start]
    today_tokens = sum(l.total_tokens for l in today_logs)
    today_cost_usd = sum(l.estimated_cost_usd for l in today_logs)
    today_cost_php = today_cost_usd * 57.50

    # Aggregate daily trends for the past 7 days
    daily_map = {}
    for i in range(6, -1, -1):
        d_str = (datetime.utcnow() - timedelta(days=i)).strftime("%Y-%m-%d")
        daily_map[d_str] = {"prompt": 0, "completion": 0, "total": 0, "cost_usd": 0.0}

    for l in logs:
        d_str = l.created_at.strftime("%Y-%m-%d")
        if d_str in daily_map:
            daily_map[d_str]["prompt"] += l.prompt_tokens
            daily_map[d_str]["completion"] += l.completion_tokens
            daily_map[d_str]["total"] += l.total_tokens
            daily_map[d_str]["cost_usd"] += l.estimated_cost_usd

    daily_points = [
        DailyTokenPoint(
            date=d,
            prompt_tokens=v["prompt"],
            completion_tokens=v["completion"],
            total_tokens=v["total"],
            cost_usd=round(v["cost_usd"], 6),
            cost_php=round(v["cost_usd"] * 57.50, 4),
        )
        for d, v in sorted(daily_map.items())
    ]

    return TokenTelemetrySummary(
        total_prompt_tokens=total_prompt,
        total_completion_tokens=total_completion,
        total_tokens=total_tokens,
        estimated_cost_usd=round(total_cost_usd, 6),
        estimated_cost_php=round(total_cost_php, 4),
        today_tokens=today_tokens,
        today_cost_usd=round(today_cost_usd, 6),
        today_cost_php=round(today_cost_php, 4),
        daily_trends=daily_points,
    )


# ── Super Admin: System Health & Observability ───────────────────────────────

@router.get("/telemetry/system-health", response_model=SystemHealthTelemetry)
def get_system_health(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get infrastructure health, connection pool status, and account tallies (Super Admin only)."""
    pool_size = 20
    pool_checked_out = 0
    pool_overflow = 0
    db_connected = True

    try:
        pool = engine.pool
        pool_size = getattr(pool, "size", lambda: 20)()
        pool_checked_out = getattr(pool, "checkedout", lambda: 0)()
        pool_overflow = getattr(pool, "overflow", lambda: 0)()
    except Exception:
        db_connected = False

    total_counselors = session.exec(select(func.count()).select_from(User).where(User.role == UserRole.counselor)).one()
    total_students = session.exec(select(func.count()).select_from(User).where(User.role == UserRole.client)).one()
    token_sum = session.exec(select(func.sum(TokenUsageLog.total_tokens))).one()
    total_tokens_consumed = int(token_sum) if token_sum else 0

    return SystemHealthTelemetry(
        status="Operational • Neon Serverless Active",
        database_connected=db_connected,
        pool_size=pool_size,
        pool_checked_out=pool_checked_out,
        pool_overflow=pool_overflow,
        total_counselors=total_counselors,
        total_students=total_students,
        total_tokens_consumed=total_tokens_consumed,
    )


# ── Process 5.0: Consistent Distress Detection (RA 11036) ───────────────────

@router.get("/distress-patterns", response_model=List[DistressPatternAlert])
def get_consistent_distress_patterns(
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    Process 5.0: Consistent Distress Detection (RA 11036 compliance).
    Identifies students who have logged persistent low moods (level 1 Distressed or level 2 Down/Rough)
    across 2 consecutive check-ins (Yellow Warning) or 3+ consecutive check-ins (Red Alert).
    """
    students = session.exec(
        select(User)
        .where(User.role == UserRole.client)
        .where(User.is_active == True)
        .where(User.is_deleted == False)
    ).all()

    alerts: List[DistressPatternAlert] = []
    mood_labels = {
        1: "Distressed",
        2: "Rough",
        3: "Okay",
        4: "Good",
        5: "Great",
    }

    for s in students:
        entries = session.exec(
            select(MoodEntry)
            .where(MoodEntry.user_id == s.id)
            .order_by(MoodEntry.created_at.desc())
            .limit(10)
        ).all()

        if not entries:
            continue

        consecutive_low = 0
        for entry in entries:
            if entry.mood_level <= 2:
                consecutive_low += 1
            else:
                break

        if consecutive_low >= 2:
            latest = entries[0]
            is_red = consecutive_low >= 3
            alerts.append(
                DistressPatternAlert(
                    user_id=s.id,
                    full_name=s.full_name or s.email.split('@')[0],
                    email=s.email,
                    consecutive_days=consecutive_low,
                    latest_mood_level=latest.mood_level,
                    latest_mood_label=mood_labels.get(latest.mood_level, "Rough"),
                    latest_note=latest.note,
                    latest_date=latest.created_at.strftime("%Y-%m-%d %H:%M"),
                    risk_level="red" if is_red else "yellow",
                    severity="High Risk (Urgent)" if is_red else "Moderate Risk",
                    recommended_action="Immediate psychological intake recommended" if is_red else "Monitor trends & conduct gentle check-in",
                )
            )

    return alerts


