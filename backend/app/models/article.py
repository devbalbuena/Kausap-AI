import uuid
from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field

class Article(SQLModel, table=True):
    __tablename__ = "article"

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    title: str = Field(index=True)
    subtitle: str
    category: str = Field(default="Mental Awareness", index=True)
    read_time: str = Field(default="4 min read")
    author: str = Field(default="Dr. Kim Vance")
    author_role: str = Field(default="Clinical Psychologist")
    image_url: Optional[str] = Field(default=None)
    theme_color_hex: str = Field(default="#0284C7")
    content_json: str = Field(default="[]")
    is_published: bool = Field(default=True, index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
