from datetime import datetime
import uuid
from typing import Optional
from sqlmodel import Field, SQLModel


class TokenUsageLog(SQLModel, table=True):
    """
    Append-only telemetry record of OpenAI / LLM token consumption.
    Enables Super Admin to monitor API costs, prompt vs completion usage, and token trends.
    """
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: Optional[uuid.UUID] = Field(default=None, foreign_key="user.id", index=True)
    session_id: Optional[uuid.UUID] = Field(default=None, foreign_key="chatsession.id", index=True)
    model: str = Field(default="gpt-4o-mini")
    prompt_tokens: int = Field(default=0)
    completion_tokens: int = Field(default=0)
    total_tokens: int = Field(default=0)
    estimated_cost_usd: float = Field(default=0.0)
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)
