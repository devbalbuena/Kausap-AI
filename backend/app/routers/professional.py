from typing import Annotated, List
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlmodel import Session, select
from app.database import get_session
from app.core.deps import get_current_user
from app.models.user import User
from app.models.session import TherapySession, SessionStatus
from app.models.chat import ChatSession, ChatMessage
from app.schemas.professional import (
    ClientListItem, ClientsResponse,
    AppointmentItem, PendingRequest, AppointmentsResponse,
    FlaggedConversation, InsightTag, AIInsightReport, MetricCard, AIInsightsResponse,
)
from datetime import datetime, timedelta
import random

router = APIRouter(prefix="/professional", tags=["Professional"])


def _require_professional(current_user: User) -> None:
    if current_user.role != "professional":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only professionals can access this resource")


def _get_assigned_clients(prof_id: uuid.UUID, db: Session) -> List[User]:
    """Return all clients who have at least one TherapySession with this professional."""
    sessions = db.exec(select(TherapySession).where(TherapySession.professional_id == prof_id)).all()
    client_ids = list(set(s.client_id for s in sessions))
    clients = []
    for cid in client_ids:
        u = db.exec(select(User).where(User.id == cid)).first()
        if u:
            clients.append(u)
    return clients


def _initials(first: str, last: str) -> str:
    return (first[0] if first else "") + (last[0] if last else "")


def _avatar_colors():
    colors = ["#0077B6", "#2E9E6B", "#E07B39", "#9B5DE5", "#F15BB5", "#00BBF9"]
    return colors[random.randint(0, len(colors) - 1)]


def _time_ago(dt: datetime) -> str:
    delta = datetime.utcnow() - dt
    if delta.days > 0:
        return f"{delta.days}d ago"
    elif delta.seconds > 3600:
        return f"{delta.seconds // 3600}h ago"
    elif delta.seconds > 60:
        return f"{delta.seconds // 60}m ago"
    return "Just now"


# ─── GET /professional/clients ────────────────────────────────────────────────
@router.get("/clients", response_model=ClientsResponse)
def get_clients(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=10, ge=1, le=50),
    risk_level: str = Query(default="all"),
):
    _require_professional(current_user)
    all_clients = _get_assigned_clients(current_user.id, db)
    total = len(all_clients)

    # Paginate
    start = (page - 1) * per_page
    paged = all_clients[start : start + per_page]

    items: List[ClientListItem] = []
    for idx, client in enumerate(paged):
        # Get next scheduled session with this professional
        next_sess = db.exec(
            select(TherapySession)
            .where(TherapySession.professional_id == current_user.id)
            .where(TherapySession.client_id == client.id)
            .where(TherapySession.status == SessionStatus.SCHEDULED)
            .order_by(TherapySession.date_time)
        ).first()

        next_appt_str = None
        if next_sess:
            mode_label = "Video" if next_sess.mode.lower() == "online" else "In-Person"
            next_appt_str = f"{next_sess.date_time.strftime('%b %d, %Y')} {next_sess.date_time.strftime('%I:%M %p')} ({mode_label})"

        # Check if any flagged messages (risk level)
        client_chat_sessions = db.exec(select(ChatSession).where(ChatSession.user_id == client.id)).all()
        chat_session_ids = [cs.id for cs in client_chat_sessions]
        has_flags = False
        if chat_session_ids:
            flagged = db.exec(
                select(ChatMessage)
                .where(ChatMessage.session_id.in_(chat_session_ids))
                .where(ChatMessage.risk_flag == True)
            ).first()
            has_flags = flagged is not None

        if has_flags:
            client_status = "High Risk"
        elif next_sess:
            client_status = "Active"
        else:
            client_status = "Maintenance"

        # Skip if filter doesn't match
        if risk_level != "all" and risk_level.lower() != client_status.lower().replace(" ", "_"):
            continue

        items.append(ClientListItem(
            id=client.id,
            first_name=client.first_name or "",
            last_name=client.last_name or "",
            initials=_initials(client.first_name or "", client.last_name or ""),
            avatar_color=_avatar_colors(),
            client_id_label=f"MC-{str(client.id)[:8].upper()}",
            payment_type="Private Pay",
            next_appointment=next_appt_str,
            status=client_status,
            location=getattr(client, 'address', None) or "—",
        ))

    return ClientsResponse(clients=items, total=total, page=page, per_page=per_page)


# ─── GET /professional/appointments ──────────────────────────────────────────
@router.get("/appointments", response_model=AppointmentsResponse)
def get_appointments(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
    date_from: str = Query(default=None),
    date_to: str = Query(default=None),
):
    _require_professional(current_user)

    query = select(TherapySession).where(TherapySession.professional_id == current_user.id)

    if date_from:
        try:
            df = datetime.fromisoformat(date_from)
            query = query.where(TherapySession.date_time >= df)
        except ValueError:
            pass

    if date_to:
        try:
            dt = datetime.fromisoformat(date_to)
            query = query.where(TherapySession.date_time <= dt)
        except ValueError:
            pass

    sessions = db.exec(query.order_by(TherapySession.date_time)).all()

    appointments: List[AppointmentItem] = []
    pending: List[PendingRequest] = []

    for s in sessions:
        client = db.exec(select(User).where(User.id == s.client_id)).first()
        if not client:
            continue

        first = client.first_name or ""
        last = client.last_name or ""
        client_name = f"{first} {last}".strip() or "Unknown"
        initials = _initials(first, last)
        mode = "Virtual" if s.mode.lower() == "online" else "In-Person"
        end_dt = s.date_time + timedelta(hours=1)

        if s.status == SessionStatus.SCHEDULED:
            appointments.append(AppointmentItem(
                id=s.id,
                client_name=client_name,
                initials=initials,
                start_time=s.date_time.strftime("%I:%M %p"),
                end_time=end_dt.strftime("%I:%M %p"),
                date=s.date_time.strftime("%Y-%m-%d"),
                mode=mode,
                reason=s.reason,
                status=s.status.value,
            ))
        elif s.status == SessionStatus.CANCELLED:
            # Treat cancelled as pending reschedule request for demo
            pending.append(PendingRequest(
                id=s.id,
                client_name=client_name,
                requested_date=s.date_time.strftime("%b %d, %Y"),
                requested_time=s.date_time.strftime("%I:%M %p"),
                mode=mode,
                reason=s.reason or "Reschedule requested",
                tag="RESCHEDULE",
            ))

    return AppointmentsResponse(appointments=appointments, pending_requests=pending)


# ─── GET /professional/ai-insights ────────────────────────────────────────────
@router.get("/ai-insights", response_model=AIInsightsResponse)
def get_ai_insights(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    _require_professional(current_user)

    clients = _get_assigned_clients(current_user.id, db)
    client_map = {c.id: c for c in clients}
    client_ids = list(client_map.keys())

    # Get all chat sessions for those clients
    chat_sessions = []
    if client_ids:
        chat_sessions = db.exec(select(ChatSession).where(ChatSession.user_id.in_(client_ids))).all()

    cs_to_client = {cs.id: cs.user_id for cs in chat_sessions}
    cs_ids = [cs.id for cs in chat_sessions]

    # Get flagged messages
    flagged_messages = []
    if cs_ids:
        flagged_messages = db.exec(
            select(ChatMessage)
            .where(ChatMessage.session_id.in_(cs_ids))
            .where(ChatMessage.risk_flag == True)
            .order_by(ChatMessage.created_at.desc())
        ).all()

    # Group by client, pick latest flagged message per client
    client_latest_flag: dict[uuid.UUID, ChatMessage] = {}
    for msg in flagged_messages:
        cid = cs_to_client.get(msg.session_id)
        if cid and cid not in client_latest_flag:
            client_latest_flag[cid] = msg

    unresolved: List[FlaggedConversation] = []
    for cid, msg in client_latest_flag.items():
        client = client_map.get(cid)
        if not client:
            continue
        first = client.first_name or ""
        last = client.last_name or ""

        # Assign severity based on content keywords (simple heuristic)
        content_lower = msg.content.lower()
        if any(w in content_lower for w in ["die", "suicide", "hurt", "overwhelm", "crisis"]):
            severity = "CRITICAL"
        elif any(w in content_lower for w in ["anxious", "depressed", "hopeless", "fear"]):
            severity = "HIGH"
        else:
            severity = "MODERATE"

        unresolved.append(FlaggedConversation(
            id=msg.id,
            client_name=f"{first[0]}. {last}".strip() if first else last,
            initials=_initials(first, last),
            time_ago=_time_ago(msg.created_at),
            preview=msg.content[:60] + ("..." if len(msg.content) > 60 else ""),
            severity=severity,
            is_resolved=False,
        ))

    # Sort by severity
    severity_order = {"CRITICAL": 0, "HIGH": 1, "MODERATE": 2}
    unresolved.sort(key=lambda x: severity_order.get(x.severity, 3))

    # Build a mocked AI Insight Report for the top flagged client
    selected_insight = None
    if unresolved:
        top = unresolved[0]
        selected_insight = AIInsightReport(
            client_name=top.client_name,
            flagged_quote=f'"{top.preview}"',
            tags=[
                InsightTag(label="Acute Stress"),
                InsightTag(label="Sleep Disruption"),
                InsightTag(label="Protocol Fatigue"),
            ],
            ai_analysis=(
                "The system detected patterns indicative of acute stress overload, "
                "noting phrases that correlate strongly with panic-like symptoms in this "
                "patient's historical baseline."
            ),
            recommended_actions=["Schedule Urgent Session", "Suggest Wellness Activity"],
        )

    # Metrics
    total_flagged = len(unresolved)
    metrics = [
        MetricCard(
            label="30 DAY TREND",
            value=f"+{total_flagged * 10}%",
            sublabel="Anxiety Flags",
            trend="up",
        ),
        MetricCard(
            label="SYSTEM RESPONSIVENESS",
            value="14 mins",
            sublabel="Average Resolution Time",
        ),
    ]

    return AIInsightsResponse(
        metrics=metrics,
        unresolved=unresolved,
        resolved=[],
        selected_insight=selected_insight,
    )
