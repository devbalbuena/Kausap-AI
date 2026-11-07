from datetime import datetime, timezone
import uuid
from typing import Optional, List
from sqlalchemy import Index
from sqlmodel import Field, SQLModel, Relationship


class ChatSessionBase(SQLModel):
    topic: Optional[str] = Field(default="Free Talk")


class ChatSession(ChatSessionBase, table=True):
    __table_args__ = (
        Index("ix_chatsession_user_created", "user_id", "created_at"),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)
    
    # Relationship to messages
    messages: List["ChatMessage"] = Relationship(back_populates="session")


class ChatMessageBase(SQLModel):
    role: str = Field(index=True) # "user" or "assistant"
    content: str
    risk_flag: bool = Field(default=False, index=True)


class ChatMessage(ChatMessageBase, table=True):
    __table_args__ = (
        Index("ix_chatmessage_risk_role_created", "risk_flag", "role", "created_at"),
        Index("ix_chatmessage_session_created", "session_id", "created_at"),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    session_id: uuid.UUID = Field(foreign_key="chatsession.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)
    
    # Relationship back to session
    session: ChatSession = Relationship(back_populates="messages")
