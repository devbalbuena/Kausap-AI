from datetime import datetime
import uuid
from sqlmodel import Field, SQLModel

class DirectMessageBase(SQLModel):
    content: str
    is_read: bool = Field(default=False)

class DirectMessage(DirectMessageBase, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    sender_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    receiver_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
