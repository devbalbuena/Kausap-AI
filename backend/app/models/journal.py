from datetime import datetime
import uuid
from typing import Optional
from sqlmodel import Field, SQLModel


class JournalEntryBase(SQLModel):
    title: Optional[str] = None
    content: str
    entry_date: str = Field(index=True)  # Format: YYYY-MM-DD
    mood_tag: Optional[str] = "🌿 Calm"
    prompt: Optional[str] = None


class JournalEntry(JournalEntryBase, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
