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
    status: str = Field(default="published", index=True) # 'draft' | 'published' | 'archived'
    is_featured: bool = Field(default=False, index=True)
    view_count: int = Field(default=0)
    share_count: int = Field(default=0)
    ai_discussion_count: int = Field(default=0)
    reaction_counts_json: str = Field(default="{}")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class ArticleReaction(SQLModel, table=True):
    __tablename__ = "article_reaction"

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    article_id: str = Field(index=True)
    user_id: Optional[str] = Field(default=None, index=True)
    emoji: str = Field(default="❤️")
    created_at: datetime = Field(default_factory=datetime.utcnow)
