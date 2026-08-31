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
    is_deleted: bool = False
    deleted_at: Optional[datetime] = None
    deactivated_at: Optional[datetime] = None
    deactivation_reason: Optional[str] = None
    reactivation_appeal: Optional[str] = None
    reactivation_appeal_at: Optional[datetime] = None
    created_at: datetime
    mood_entries_count: int
    chat_sessions_count: int
    flagged_messages_count: Optional[int] = 0
    phone_number: Optional[str] = None
    birthday: Optional[str] = None
    gender: Optional[str] = None
    occupation: Optional[str] = None
    nationality: Optional[str] = "Filipino"
    hobbies: Optional[str] = None


class FlaggedMessageRead(BaseModel):
    id: uuid.UUID
    session_id: Optional[uuid.UUID] = None
    user_id: uuid.UUID
    user_email: str
    user_name: Optional[str] = None
    role: str
    content: str
    created_at: datetime
    is_resolved: Optional[bool] = False
    resolved_at: Optional[datetime] = None
    resolution_note: Optional[str] = None
    flag_reason: Optional[str] = "Crisis Trigger"
    risk_level: Optional[str] = "red"


class UserDetail(BaseModel):
    id: uuid.UUID
    email: str
    full_name: Optional[str]
    role: str
    is_active: bool
    is_deleted: bool = False
    deleted_at: Optional[datetime] = None
    deactivated_at: Optional[datetime] = None
    deactivation_reason: Optional[str] = None
    reactivation_appeal: Optional[str] = None
    reactivation_appeal_at: Optional[datetime] = None
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
    total_students: Optional[int] = 0
    total_active_students: Optional[int] = 0
    total_mood_entries: int
    total_chat_sessions: int
    total_flagged_messages: int
    total_counselors: Optional[int] = 0
    mood_distribution: Optional[Dict[str, int]] = None


# ── Counselor Management Schemas ─────────────────────────────────────────────

class CounselorSendVerificationRequest(BaseModel):
    email: str
    first_name: str
    last_name: str


class CounselorCreate(BaseModel):
    email: str
    password: str
    first_name: str
    last_name: str
    phone_number: str
    department_title: Optional[str] = "Guidance Counselor"
    gender: Optional[str] = "Female"
    verification_code: Optional[str] = None


class CounselorRead(BaseModel):
    id: uuid.UUID
    email: str
    full_name: str
    role: str
    department_title: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    is_active: bool
    created_at: datetime


class CounselorStatusUpdate(BaseModel):
    is_active: bool


class CounselorPasswordReset(BaseModel):
    new_password: str


# ── AI Token & Cost Telemetry Schemas ────────────────────────────────────────

class DailyTokenPoint(BaseModel):
    date: str
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    cost_usd: float
    cost_php: float


class TokenTelemetrySummary(BaseModel):
    total_prompt_tokens: int
    total_completion_tokens: int
    total_tokens: int
    estimated_cost_usd: float
    estimated_cost_php: float
    today_tokens: int
    today_cost_usd: float
    today_cost_php: float
    daily_trends: List[DailyTokenPoint]


class SystemHealthTelemetry(BaseModel):
    status: str
    database_connected: bool
    pool_size: int
    pool_checked_out: int
    pool_overflow: int
    total_counselors: int
    total_students: int
    total_tokens_consumed: int


class DistressPatternAlert(BaseModel):
    user_id: uuid.UUID
    full_name: str
    email: str
    consecutive_days: int
    latest_mood_level: int
    latest_mood_label: str
    latest_note: Optional[str] = None
    latest_date: str
    risk_level: str = "red"  # "yellow" (2 days) | "red" (3+ days)
    severity: str = "High Risk"
    recommended_action: str = "Immediate intake outreach recommended"

