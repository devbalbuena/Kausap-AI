from datetime import datetime
import re
import uuid
from typing import Optional, Union, List
from pydantic import field_validator
from sqlmodel import Field, SQLModel

_CONTROL_CHARS_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


class MoodEntryCreate(SQLModel):
    mood_level: int = Field(ge=1, le=5)  # 1-5
    emotions: Optional[Union[str, List[str]]] = None
    intensity: Optional[int] = Field(default=None, ge=1, le=10)
    note: Optional[str] = Field(default=None, max_length=2000)

    @field_validator("note")
    @classmethod
    def sanitize_note(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = _CONTROL_CHARS_RE.sub("", v).strip()
        return cleaned if cleaned else None


class MoodEntryRead(SQLModel):
    id: uuid.UUID
    user_id: uuid.UUID
    mood_level: int
    emotions: Optional[str]
    intensity: Optional[int]
    note: Optional[str]
    created_at: datetime


class MoodEntryUpdate(SQLModel):
    mood_level: Optional[int] = Field(default=None, ge=1, le=5)
    emotions: Optional[Union[str, List[str]]] = None
    intensity: Optional[int] = Field(default=None, ge=1, le=10)
    note: Optional[str] = Field(default=None, max_length=2000)

    @field_validator("note")
    @classmethod
    def sanitize_note(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = _CONTROL_CHARS_RE.sub("", v).strip()
        return cleaned if cleaned else None


class MoodSummary(SQLModel):
    avg_mood_7d: Optional[float]
    count_7d: int
    avg_mood_30d: Optional[float]
    count_30d: int
