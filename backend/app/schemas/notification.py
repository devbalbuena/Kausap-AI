import uuid
from datetime import datetime
from pydantic import BaseModel
from app.models.notification import NotificationType


from typing import Optional


class NotificationRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    body: str
    type: NotificationType
    is_read: bool
    is_deleted: bool = False
    is_acknowledged: bool = False
    acknowledged_at: Optional[datetime] = None
    call_slip_json: Optional[str] = None
    created_at: datetime

