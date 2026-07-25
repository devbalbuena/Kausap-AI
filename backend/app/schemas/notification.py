import uuid
from datetime import datetime
from pydantic import BaseModel
from app.models.notification import NotificationType


class NotificationRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    body: str
    type: NotificationType
    is_read: bool
    created_at: datetime
