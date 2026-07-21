from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
import uuid

class TriageAlert(BaseModel):
    id: uuid.UUID
    client_name: str
    flag_type: str
    description: str
    time_ago: str
    chat_message_id: Optional[uuid.UUID] = None
    created_at: datetime

class StatCounts(BaseModel):
    active_patients: int
    pending_requests: int

class ScheduleItem(BaseModel):
    id: uuid.UUID
    client_name: str
    time: str
    type: str # "Intake Assessment", "Follow-up Session", etc.
    mode: str # "Virtual" or "In-Person"

class DashboardData(BaseModel):
    alerts: List[TriageAlert]
    stats: StatCounts
    schedule: List[ScheduleItem]
