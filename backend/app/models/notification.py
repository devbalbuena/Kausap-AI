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


class NotificationBase(SQLModel):
    title: str
    body: str
    type: NotificationType = Field(default=NotificationType.system)
    is_read: bool = Field(default=False)
    is_deleted: bool = Field(default=False)


class Notification(NotificationBase, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
