from datetime import datetime
import uuid
from typing import List, Optional, Dict
from pydantic import BaseModel
from app.schemas.mood import MoodEntryRead
from app.schemas.chat import ChatSessionRead


class UserSummary(BaseModel):
    id: uuid.UUID
    email: str
    full_name: Optional[str]
    role: str
    is_active: bool
    created_at: datetime
    mood_entries_count: int
    chat_sessions_count: int
    flagged_messages_count: Optional[int] = 0
    phone_number: Optional[str] = None
    birthday: Optional[str] = None
    gender: Optional[str] = None
    occupation: Optional[str] = None


class FlaggedMessageRead(BaseModel):
    id: uuid.UUID
    session_id: uuid.UUID
    user_id: uuid.UUID
    user_email: str
    role: str
    content: str
    created_at: datetime


class UserDetail(BaseModel):
    id: uuid.UUID
    email: str
    full_name: Optional[str]
    role: str
    is_active: bool
    created_at: datetime
    phone_number: Optional[str] = None
    birthday: Optional[str] = None
    gender: Optional[str] = None
    occupation: Optional[str] = None
    recent_moods: List[MoodEntryRead]
    recent_sessions: List[ChatSessionRead]


class AdminStats(BaseModel):
    total_users: int
    total_active_users: int
    total_mood_entries: int
    total_chat_sessions: int
    total_flagged_messages: int
    mood_distribution: Optional[Dict[str, int]] = None
