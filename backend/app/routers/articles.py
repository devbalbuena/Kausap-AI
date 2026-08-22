from datetime import datetime
from typing import Annotated, List, Optional
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlmodel import Session, select

from app.database import get_session
from app.core.deps import get_current_admin
from app.models.user import User
from app.models.article import Article

router = APIRouter(prefix="/articles", tags=["Articles"])
admin_router = APIRouter(prefix="/admin/articles", tags=["Admin Articles"])

class ArticleCreate(BaseModel):
    title: str
    subtitle: str
    category: str = "Mental Awareness"
    read_time: str = "4 min read"
    author: str = "CSU Guidance Center"
    author_role: str = "Counselor & Mental Health Specialist"
    image_url: Optional[str] = None
    theme_color_hex: str = "#0284C7"
    content_json: str = "[]"
    is_published: bool = True

class ArticleUpdate(BaseModel):
    title: Optional[str] = None
    subtitle: Optional[str] = None
    category: Optional[str] = None
    read_time: Optional[str] = None
    author: Optional[str] = None
    author_role: Optional[str] = None
    image_url: Optional[str] = None
    theme_color_hex: Optional[str] = None
    content_json: Optional[str] = None
    is_published: Optional[bool] = None

class ArticleRead(BaseModel):
    id: str
    title: str
    subtitle: str
    category: str
    read_time: str
    author: str
    author_role: str
    image_url: Optional[str] = None
    theme_color_hex: str
    content_json: str
    is_published: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ── Public / Student Endpoints ───────────────────────────────────────────────

@router.get("", response_model=List[ArticleRead])
def list_published_articles(
    session: Annotated[Session, Depends(get_session)],
    category: Optional[str] = None,
    search: Optional[str] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
):
    """List published mental wellness articles with optional category and search filters."""
    query = select(Article).where(Article.is_published == True)
    if category and category != "All":
        query = query.where(Article.category == category)
    if search:
        search_pattern = f"%{search}%"
        query = query.where(
            (Article.title.ilike(search_pattern)) |
            (Article.subtitle.ilike(search_pattern)) |
            (Article.category.ilike(search_pattern))
        )
    query = query.order_by(Article.created_at.desc()).limit(limit)
    return session.exec(query).all()

@router.get("/{article_id}", response_model=ArticleRead)
def get_article(
    article_id: str,
    session: Annotated[Session, Depends(get_session)],
):
    """Retrieve a single article by ID."""
    article = session.get(Article, article_id)
    if not article:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Article not found")
    return article

# ── Admin Management Endpoints ───────────────────────────────────────────────

@admin_router.get("", response_model=List[ArticleRead])
def admin_list_all_articles(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """List all articles including drafts (Admin only)."""
    query = select(Article).order_by(Article.created_at.desc())
    return session.exec(query).all()

@admin_router.post("", response_model=ArticleRead, status_code=status.HTTP_201_CREATED)
def admin_create_article(
    payload: ArticleCreate,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Create and publish a new psychoeducation article (Admin only)."""
    article = Article(
        id=str(uuid.uuid4()),
        title=payload.title,
        subtitle=payload.subtitle,
        category=payload.category,
        read_time=payload.read_time,
        author=payload.author,
        author_role=payload.author_role,
        image_url=payload.image_url,
        theme_color_hex=payload.theme_color_hex,
        content_json=payload.content_json,
        is_published=payload.is_published,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    session.add(article)
    session.commit()
    session.refresh(article)
    return article

@admin_router.put("/{article_id}", response_model=ArticleRead)
def admin_update_article(
    article_id: str,
    payload: ArticleUpdate,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Update an existing psychoeducation article (Admin only)."""
    article = session.get(Article, article_id)
    if not article:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Article not found")

    update_data = payload.dict(exclude_unset=True)
    for field, val in update_data.items():
        setattr(article, field, val)
    article.updated_at = datetime.utcnow()

    session.add(article)
    session.commit()
    session.refresh(article)
    return article

@admin_router.delete("/{article_id}", status_code=status.HTTP_204_NO_CONTENT)
def admin_delete_article(
    article_id: str,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Delete a psychoeducation article (Admin only)."""
    article = session.get(Article, article_id)
    if not article:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Article not found")
    session.delete(article)
    session.commit()
    return None
