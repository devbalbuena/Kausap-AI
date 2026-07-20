from datetime import datetime
import uuid
from typing import Optional
from enum import Enum
from sqlmodel import Field, SQLModel

class SessionStatus(str, Enum):
    SCHEDULED = "scheduled"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class TherapySessionBase(SQLModel):
    professional_id: uuid.UUID
    date_time: datetime
    reason: str
    mode: str
    notes: Optional[str] = Field(default=None)

class TherapySession(TherapySessionBase, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    client_id: uuid.UUID = Field(foreign_key="user.id")
    status: SessionStatus = Field(default=SessionStatus.SCHEDULED)
    created_at: datetime = Field(default_factory=datetime.utcnow)
