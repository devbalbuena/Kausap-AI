from datetime import datetime
import uuid
from typing import Optional
from enum import Enum
from sqlmodel import Field, SQLModel


class NotificationType(str, Enum):
    session = "session"
    message = "message"
    alert = "alert"
    system = "system"
    guidance_notice = "guidance_notice"


class NotificationBase(SQLModel):
    title: str
    body: str
    type: NotificationType = Field(default=NotificationType.system)
    is_read: bool = Field(default=False)
    is_deleted: bool = Field(default=False)
    is_acknowledged: bool = Field(default=False)
    acknowledged_at: Optional[datetime] = Field(default=None)
    call_slip_json: Optional[str] = Field(default=None)


class Notification(NotificationBase, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
