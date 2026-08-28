import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class JournalCreate(BaseModel):
    title: Optional[str] = None
    content: str
    entry_date: Optional[str] = None  # Defaults to today YYYY-MM-DD
    mood_tag: Optional[str] = "🌿 Calm"
    prompt: Optional[str] = None


class JournalUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    mood_tag: Optional[str] = None
    prompt: Optional[str] = None


class JournalRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: Optional[str] = None
    content: str
    entry_date: str
    mood_tag: Optional[str] = None
    prompt: Optional[str] = None
    created_at: datetime
    updated_at: datetime
