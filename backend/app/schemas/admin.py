from datetime import datetime
import uuid
from typing import List, Optional
from pydantic import BaseModel
from app.schemas.mood import MoodEntryRead
from app.schemas.chat import ChatSessionRead
from app.schemas.referral import DoctorReferralRead


class UserSummary(BaseModel):
    id: uuid.UUID
    email: str
    full_name: Optional[str]
    role: str
    is_active: bool
    created_at: datetime
    mood_entries_count: int
    chat_sessions_count: int


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
    recent_moods: List[MoodEntryRead]
    recent_sessions: List[ChatSessionRead]
    referrals: List[DoctorReferralRead]


class AdminStats(BaseModel):
    total_users: int
    total_active_users: int
    total_mood_entries: int
    total_chat_sessions: int
    total_flagged_messages: int
    total_referrals: int
