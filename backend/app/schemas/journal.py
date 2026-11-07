import re
import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator

_CONTROL_CHARS_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


class JournalCreate(BaseModel):
    title: Optional[str] = Field(default=None, max_length=200)
    content: str = Field(min_length=1, max_length=10000)
    entry_date: Optional[str] = Field(default=None, max_length=20)  # Defaults to today YYYY-MM-DD
    mood_tag: Optional[str] = Field(default=None, max_length=64)
    prompt: Optional[str] = Field(default=None, max_length=300)

    @field_validator("content")
    @classmethod
    def sanitize_content(cls, v: str) -> str:
        cleaned = _CONTROL_CHARS_RE.sub("", v or "").strip()
        if not cleaned:
            raise ValueError("Journal entry content cannot be empty or whitespace only.")
        return cleaned


class JournalUpdate(BaseModel):
    title: Optional[str] = Field(default=None, max_length=200)
    content: Optional[str] = Field(default=None, max_length=10000)
    mood_tag: Optional[str] = Field(default=None, max_length=64)
    prompt: Optional[str] = Field(default=None, max_length=300)

    @field_validator("content")
    @classmethod
    def sanitize_optional_content(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = _CONTROL_CHARS_RE.sub("", v).strip()
        if not cleaned:
            raise ValueError("Journal entry content cannot be empty or whitespace only.")
        return cleaned


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
