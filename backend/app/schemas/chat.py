from datetime import datetime
import uuid
from typing import List, Optional
from pydantic import BaseModel
from sqlmodel import SQLModel


class ChatMessageCreate(BaseModel):
    content: str


class ChatMessageRead(SQLModel):
    id: uuid.UUID
    session_id: uuid.UUID
    role: str
    content: str
    risk_flag: bool
    created_at: datetime


class ChatSessionRead(SQLModel):
    id: uuid.UUID
    user_id: uuid.UUID
    topic: Optional[str]
    created_at: datetime
    messages: List[ChatMessageRead] = []
