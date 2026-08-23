from datetime import datetime
from typing import Annotated, Dict, List, Optional
import json
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlmodel import Session, select

from app.database import get_session
from app.core.deps import get_current_admin, get_current_user_optional
from app.models.user import User
from app.models.article import Article, ArticleReaction

router = APIRouter(prefix="/articles", tags=["Articles"])
admin_router = APIRouter(prefix="/admin/articles", tags=["Admin Articles"])

class ArticleCreate(BaseModel):
    title: str
    subtitle: str
    category: str = "Mental Awareness"
    status: str = "published"
    is_featured: bool = False
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
    status: Optional[str] = None
    is_featured: Optional[bool] = None
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
    status: str
    is_featured: bool
    view_count: int
    share_count: int
    ai_discussion_count: int
    reaction_counts: Dict[str, int] = {}
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ReactionRequest(BaseModel):
    emoji: str
    label: Optional[str] = None

def _format_article_read(article: Article) -> dict:
    reactions = {}
    if article.reaction_counts_json:
        try:
            reactions = json.loads(article.reaction_counts_json)
        except Exception:
            reactions = {}
    return {
        "id": article.id,
        "title": article.title,
        "subtitle": article.subtitle,
        "category": article.category,
        "read_time": article.read_time,
        "author": article.author,
        "author_role": article.author_role,
        "image_url": article.image_url,
        "theme_color_hex": article.theme_color_hex,
        "content_json": article.content_json,
        "is_published": article.is_published,
        "status": article.status,
        "is_featured": article.is_featured,
        "view_count": article.view_count,
        "share_count": article.share_count,
        "ai_discussion_count": article.ai_discussion_count,
        "reaction_counts": reactions,
        "created_at": article.created_at,
        "updated_at": article.updated_at,
    }

# ── Public / Student Endpoints ───────────────────────────────────────────────

@router.get("", response_model=List[ArticleRead])
def list_published_articles(
    session: Annotated[Session, Depends(get_session)],
    category: Optional[str] = None,
    search: Optional[str] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
):
    """List published mental wellness articles with optional category and search filters."""
    query = select(Article).where(Article.is_published == True).where(Article.status == "published")
    if category and category != "All":
        query = query.where(Article.category == category)
    if search:
        search_pattern = f"%{search}%"
        query = query.where(
            (Article.title.ilike(search_pattern)) |
            (Article.subtitle.ilike(search_pattern)) |
            (Article.category.ilike(search_pattern))
        )
    query = query.order_by(Article.is_featured.desc(), Article.created_at.desc()).limit(limit)
    articles = session.exec(query).all()
    return [_format_article_read(a) for a in articles]

@router.get("/{article_id}", response_model=ArticleRead)
def get_article(
    article_id: str,
    session: Annotated[Session, Depends(get_session)],
):
    """Retrieve a single article by ID and increment view count."""
    article = session.get(Article, article_id)
    if not article:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Article not found")
    article.view_count += 1
    session.add(article)
    session.commit()
    session.refresh(article)
    return _format_article_read(article)

@router.post("/{article_id}/react", status_code=status.HTTP_200_OK)
def react_to_article(
    article_id: str,
    payload: ReactionRequest,
    session: Annotated[Session, Depends(get_session)],
    current_user: Annotated[Optional[User], Depends(get_current_user_optional)] = None,
):
    """Record a user emoji reaction on an article."""
    article = session.get(Article, article_id)
    if not article:
        # If dynamic article not on server, acknowledge gracefully
        return {"status": "ok", "article_id": article_id, "emoji": payload.emoji}

    # Record reaction event
    reaction_event = ArticleReaction(
        id=str(uuid.uuid4()),
        article_id=article_id,
        user_id=current_user.id if current_user else None,
        emoji=payload.emoji,
        created_at=datetime.utcnow(),
    )
    session.add(reaction_event)

    # Update summary counts JSON
    counts = {}
    if article.reaction_counts_json:
        try:
            counts = json.loads(article.reaction_counts_json)
        except Exception:
            counts = {}
    counts[payload.emoji] = counts.get(payload.emoji, 0) + 1
    article.reaction_counts_json = json.dumps(counts)
    session.add(article)
    session.commit()

    return {"status": "ok", "reaction_counts": counts}

# ── Admin Management Endpoints ───────────────────────────────────────────────

@admin_router.get("", response_model=List[ArticleRead])
def admin_list_all_articles(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """List all articles including drafts and archived (Admin only)."""
    query = select(Article).order_by(Article.created_at.desc())
    articles = session.exec(query).all()
    return [_format_article_read(a) for a in articles]

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
        status=payload.status,
        is_featured=payload.is_featured,
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
    return _format_article_read(article)

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
    return _format_article_read(article)

@admin_router.patch("/{article_id}", response_model=ArticleRead)
def admin_patch_article(
    article_id: str,
    payload: ArticleUpdate,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Partially update an article (e.g. toggle is_featured, change status)."""
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
    return _format_article_read(article)

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
