from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
import uuid


# ─── Clients ──────────────────────────────────────────────────────────────────
class ClientListItem(BaseModel):
    id: uuid.UUID
    first_name: str
    last_name: str
    initials: str
    avatar_color: str
    client_id_label: str       # e.g. "MC-2023-001"
    payment_type: str          # e.g. "Private Pay"
    next_appointment: Optional[str] = None   # e.g. "Oct 24, 2023 10:00 AM (Video)"
    status: str                # "Active" | "High Risk" | "Maintenance"
    location: str

class ClientsResponse(BaseModel):
    clients: List[ClientListItem]
    total: int
    page: int
    per_page: int


# ─── Appointments ──────────────────────────────────────────────────────────────
class AppointmentItem(BaseModel):
    id: uuid.UUID
    client_name: str
    initials: str
    start_time: str            # e.g. "09:00 AM"
    end_time: str              # e.g. "10:00 AM"
    date: str                  # ISO date string
    mode: str                  # "Virtual" | "In-Person"
    reason: str
    status: str                # "scheduled" | "completed" | "cancelled"

class PendingRequest(BaseModel):
    id: uuid.UUID
    client_name: str
    requested_date: str
    requested_time: str
    mode: str
    reason: str
    tag: str                   # "NEW" | "RESCHEDULE"

class AppointmentsResponse(BaseModel):
    appointments: List[AppointmentItem]
    pending_requests: List[PendingRequest]


# ─── AI Insights ──────────────────────────────────────────────────────────────
class FlaggedConversation(BaseModel):
    id: uuid.UUID
    client_name: str
    initials: str
    time_ago: str
    preview: str
    severity: str              # "CRITICAL" | "HIGH" | "MODERATE"
    is_resolved: bool

class InsightTag(BaseModel):
    label: str

class AIInsightReport(BaseModel):
    client_name: str
    flagged_quote: str
    tags: List[InsightTag]
    ai_analysis: str
    recommended_actions: List[str]

class MetricCard(BaseModel):
    label: str
    value: str
    sublabel: str
    trend: Optional[str] = None   # e.g. "+30%"

class AIInsightsResponse(BaseModel):
    metrics: List[MetricCard]
    unresolved: List[FlaggedConversation]
    resolved: List[FlaggedConversation]
    selected_insight: Optional[AIInsightReport] = None
