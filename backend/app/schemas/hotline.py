from datetime import datetime
import re
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator

_CONTROL_CHARS_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
_ALLOWED_CATEGORIES = {"campus", "national", "emergency"}
_ALLOWED_TYPES = {"call", "sms"}


class HotlineBase(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    phone: str = Field(min_length=1, max_length=80)
    email: Optional[str] = Field(default=None, max_length=160)
    description: Optional[str] = Field(default=None, max_length=500)
    category: str = "national"  # 'campus' | 'national' | 'emergency'
    type: str = "call"  # 'call' | 'sms'
    is_active: bool = True
    sort_order: int = Field(default=0, ge=0, le=1000)

    @field_validator("name", "phone")
    @classmethod
    def sanitize_required_text(cls, v: str) -> str:
        cleaned = _CONTROL_CHARS_RE.sub("", v or "").strip()
        if not cleaned:
            raise ValueError("Field cannot be empty or whitespace only.")
        return cleaned

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        c = (v or "national").strip().lower()
        if c not in _ALLOWED_CATEGORIES:
            raise ValueError(f"category must be one of {sorted(_ALLOWED_CATEGORIES)}")
        return c

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        t = (v or "call").strip().lower()
        if t not in _ALLOWED_TYPES:
            raise ValueError(f"type must be one of {sorted(_ALLOWED_TYPES)}")
        return t


class HotlineCreate(HotlineBase):
    pass


class HotlineUpdate(BaseModel):
    name: Optional[str] = Field(default=None, max_length=160)
    phone: Optional[str] = Field(default=None, max_length=80)
    email: Optional[str] = Field(default=None, max_length=160)
    description: Optional[str] = Field(default=None, max_length=500)
    category: Optional[str] = None
    type: Optional[str] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = Field(default=None, ge=0, le=1000)


class HotlineRead(HotlineBase):
    id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
