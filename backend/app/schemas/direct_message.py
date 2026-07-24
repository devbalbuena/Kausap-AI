import uuid
from datetime import datetime
from pydantic import BaseModel

class DirectMessageCreate(BaseModel):
    content: str
    receiver_id: uuid.UUID

class DirectMessageRead(BaseModel):
    id: uuid.UUID
    sender_id: uuid.UUID
    receiver_id: uuid.UUID
    content: str
    is_read: bool
    created_at: datetime
