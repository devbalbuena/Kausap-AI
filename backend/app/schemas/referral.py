from datetime import datetime
import uuid
from typing import Optional
from sqlmodel import SQLModel


class DoctorReferralCreate(SQLModel):
    doctor_name: str
    specialty: str
    contact_info: str
    notes: Optional[str] = None


class DoctorReferralRead(SQLModel):
    id: uuid.UUID
    user_id: uuid.UUID
    doctor_name: str
    specialty: str
    contact_info: str
    notes: Optional[str]
    created_at: datetime


class DoctorReferralUpdate(SQLModel):
    doctor_name: Optional[str] = None
    specialty: Optional[str] = None
    contact_info: Optional[str] = None
    notes: Optional[str] = None
