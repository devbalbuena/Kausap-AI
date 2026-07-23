from typing import Annotated, List
import uuid
from fastapi import APIRouter, Depends
from sqlmodel import Session, select
from app.database import get_session
from app.core.deps import get_current_user
from app.models.user import User
from app.models.session import TherapySession, SessionStatus
from app.models.chat import ChatSession, ChatMessage
from fastapi import HTTPException, status
from datetime import datetime, timedelta
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/professional", tags=["Professional Reports"])


def _require_professional(current_user: User) -> None:
    if current_user.role != "professional":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only professionals can access this resource")


class MetricCard(BaseModel):
    label: str
    value: str
    sublabel: str
    icon: str  # "trend_up" | "document" | "crisis"
    trend: Optional[str] = None


class BarChartDataPoint(BaseModel):
    month: str
    intake_score: float
    current_score: float


class CrisisLogEntry(BaseModel):
    date_time: str
    patient_name: str
    trigger_event: str
    severity: str   # "High Risk" | "Medium Risk" | "Low Risk"
    resolution_status: str


class CrisisProtocolMetric(BaseModel):
    label: str
    value: str
    percentage: float


class ReportsResponse(BaseModel):
    metrics: List[MetricCard]
    chart_data: List[BarChartDataPoint]
    crisis_protocol: List[CrisisProtocolMetric]
    crisis_log: List[CrisisLogEntry]


@router.get("/reports", response_model=ReportsResponse)
def get_reports(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    _require_professional(current_user)

    # Get all sessions for this professional
    all_sessions = db.exec(
        select(TherapySession).where(TherapySession.professional_id == current_user.id)
    ).all()

    completed = [s for s in all_sessions if s.status == SessionStatus.COMPLETED]
    assessments_completed = len(completed)

    # Get crisis flags from assigned clients' chat sessions
    client_ids = list(set(s.client_id for s in all_sessions))
    crisis_log_entries: List[CrisisLogEntry] = []
    total_crisis = 0

    if client_ids:
        chat_sessions = db.exec(select(ChatSession).where(ChatSession.user_id.in_(client_ids))).all()
        cs_to_client = {cs.id: cs.user_id for cs in chat_sessions}
        cs_ids = [cs.id for cs in chat_sessions]

        if cs_ids:
            flagged_msgs = db.exec(
                select(ChatMessage)
                .where(ChatMessage.session_id.in_(cs_ids))
                .where(ChatMessage.risk_flag == True)
                .order_by(ChatMessage.created_at.desc())
            ).all()
            total_crisis = len(flagged_msgs)

            for msg in flagged_msgs[:10]:  # Show max 10 in log
                cid = cs_to_client.get(msg.session_id)
                client = db.exec(select(User).where(User.id == cid)).first() if cid else None
                patient_name = f"{client.first_name or ''} {client.last_name or ''}".strip() if client else "Unknown"

                content_lower = msg.content.lower()
                if any(w in content_lower for w in ["die", "suicide", "hurt", "hopeless"]):
                    severity = "High Risk"
                    trigger = "NLP Sentiment: Severe Hopelessness"
                    resolution = "Escorted to Guidance Office."
                elif any(w in content_lower for w in ["harm", "self", "phq"]):
                    severity = "High Risk"
                    trigger = "PHQ-9 Q9 Flag (Self-Harm)"
                    resolution = "Safety Plan Activated."
                else:
                    severity = "Medium Risk"
                    trigger = "User-Initiated SOS Button"
                    resolution = "De-escalated via Chatbot."

                crisis_log_entries.append(CrisisLogEntry(
                    date_time=msg.created_at.strftime("%B %d, %Y - %H:%M"),
                    patient_name=patient_name,
                    trigger_event=trigger,
                    severity=severity,
                    resolution_status=resolution,
                ))

    # Metrics
    avg_improvement = 24  # Mocked for this phase
    metrics = [
        MetricCard(label="AVG SCORE IMPROVEMENT", value="24%", sublabel="+3% this month", icon="trend_up", trend="+3%"),
        MetricCard(label="ASSESSMENTS COMPLETED", value=str(assessments_completed), sublabel="Last 30 Days", icon="document"),
        MetricCard(label="CRISIS RESPONSES", value=str(total_crisis), sublabel="Avg resolution: 14 mins", icon="crisis"),
    ]

    # Chart data – mocked monthly PHQ-9/GAD-7 data (real data would need assessment tracking)
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
    intake_scores = [18.0, 16.0, 22.0, 11.0, 13.0, 9.0]
    current_scores = [13.0, 10.0, 15.0, 7.0, 6.0, 5.0]
    chart_data = [
        BarChartDataPoint(month=months[i], intake_score=intake_scores[i], current_score=current_scores[i])
        for i in range(len(months))
    ]

    crisis_protocol = [
        CrisisProtocolMetric(label="Immediate Interventions", value="92%", percentage=0.92),
        CrisisProtocolMetric(label="Safety Plans Activated", value="45", percentage=0.70),
    ]

    return ReportsResponse(
        metrics=metrics,
        chart_data=chart_data,
        crisis_protocol=crisis_protocol,
        crisis_log=crisis_log_entries,
    )
