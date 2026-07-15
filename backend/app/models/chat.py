from datetime import datetime
import uuid
from typing import Optional, List
from sqlmodel import Field, SQLModel, Relationship


class ChatSessionBase(SQLModel):
    topic: Optional[str] = Field(default="Free Talk")


class ChatSession(ChatSessionBase, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationship to messages
    messages: List["ChatMessage"] = Relationship(back_populates="session")


class ChatMessageBase(SQLModel):
    role: str = Field(index=True) # "user" or "assistant"
    content: str
    risk_flag: bool = Field(default=False)


class ChatMessage(ChatMessageBase, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    session_id: uuid.UUID = Field(foreign_key="chatsession.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationship back to session
    session: ChatSession = Relationship(back_populates="messages")
