from datetime import datetime
import uuid
from typing import Optional
from sqlmodel import Field, SQLModel


class MoodEntryBase(SQLModel):
    mood_level: int = Field(ge=1, le=5) # 1 to 5 scale
    emotions: Optional[str] = Field(default=None)
    intensity: Optional[int] = Field(default=None)
    note: Optional[str] = Field(default=None)


class MoodEntry(MoodEntryBase, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)
