import uuid
from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field

class EmergencyHotline(SQLModel, table=True):
    __tablename__ = "emergency_hotline"

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    name: str = Field(index=True)
    phone: str
    email: Optional[str] = Field(default=None)
    description: Optional[str] = Field(default=None)
    category: str = Field(default="national", index=True)  # 'campus' | 'national' | 'emergency'
    type: str = Field(default="call")  # 'call' | 'sms'
    is_active: bool = Field(default=True, index=True)
    sort_order: int = Field(default=0, index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
