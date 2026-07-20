from datetime import datetime
import uuid
from typing import Optional
from pydantic import BaseModel
from app.models.session import SessionStatus

class TherapySessionCreate(BaseModel):
    professional_id: uuid.UUID
    date_time: datetime
    reason: str
    mode: str
    notes: Optional[str] = None

class TherapySessionRead(BaseModel):
    id: uuid.UUID
    client_id: uuid.UUID
    professional_id: uuid.UUID
    date_time: datetime
    reason: str
    mode: str
    status: SessionStatus
    notes: Optional[str] = None
    created_at: datetime
