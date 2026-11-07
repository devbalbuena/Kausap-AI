from datetime import datetime
import re
import uuid
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, field_validator
from sqlmodel import SQLModel

_CONTROL_CHARS_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


class ChatMessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=4000)
    persona: Optional[str] = Field(default="buddy", max_length=64)
    custom_system_prompt: Optional[str] = Field(default=None, max_length=2000)
    screener_context: Optional[List[Dict[str, Any]]] = None

    @field_validator("content")
    @classmethod
    def sanitize_content(cls, v: str) -> str:
        cleaned = _CONTROL_CHARS_RE.sub("", v or "").strip()
        if not cleaned:
            raise ValueError("Message content cannot be empty or whitespace only.")
        return cleaned


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
