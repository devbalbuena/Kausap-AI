from datetime import datetime
import uuid
from typing import Optional
from sqlmodel import SQLModel


class MoodEntryCreate(SQLModel):
    mood_level: int  # 1-5
    note: Optional[str] = None


class MoodEntryRead(SQLModel):
    id: uuid.UUID
    user_id: uuid.UUID
    mood_level: int
    note: Optional[str]
    created_at: datetime


class MoodEntryUpdate(SQLModel):
    mood_level: Optional[int] = None
    note: Optional[str] = None


class MoodSummary(SQLModel):
    avg_mood_7d: Optional[float]
    count_7d: int
    avg_mood_30d: Optional[float]
    count_30d: int
