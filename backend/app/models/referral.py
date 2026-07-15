from datetime import datetime
import uuid
from typing import Optional
from sqlmodel import Field, SQLModel


class DoctorReferralBase(SQLModel):
    doctor_name: str
    specialty: str
    contact_info: str
    notes: Optional[str] = Field(default=None)


class DoctorReferral(DoctorReferralBase, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)
