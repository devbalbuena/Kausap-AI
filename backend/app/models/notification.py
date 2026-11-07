from datetime import datetime
import uuid
from typing import Optional
from enum import Enum
from sqlalchemy import Index
from sqlmodel import Field, SQLModel


class NotificationType(str, Enum):
    session = "session"
    message = "message"
    alert = "alert"
    system = "system"
    guidance_notice = "guidance_notice"


# Title used for the instant counselor escalation sent when a student reaches a 3-day Red Alert.
# The daily counselor summary ignores notifications with this title when deciding whether it still
# needs to generate that day's digest, so the instant alert never suppresses the digest.
RED_ALERT_TITLE = "🚨 Red Alert: 3-Day Low Mood"


class NotificationBase(SQLModel):
    title: str
    body: str
    type: NotificationType = Field(default=NotificationType.system)
    is_read: bool = Field(default=False, index=True)
    is_deleted: bool = Field(default=False, index=True)
    is_acknowledged: bool = Field(default=False)
    acknowledged_at: Optional[datetime] = Field(default=None)
    call_slip_json: Optional[str] = Field(default=None)


class Notification(NotificationBase, table=True):
    __table_args__ = (
        Index("ix_notification_user_deleted_created", "user_id", "is_deleted", "created_at"),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)
