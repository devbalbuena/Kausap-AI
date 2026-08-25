from datetime import datetime
from typing import Annotated, Dict, List, Optional
import json
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlmodel import Session, select

from app.database import get_session
from app.core.deps import get_current_counselor_or_admin, get_current_user_optional
from app.models.user import User
from app.models.article import Article, ArticleReaction
from app.models.audit_log import AuditLog

router = APIRouter(prefix="/articles", tags=["Articles"])
admin_router = APIRouter(prefix="/admin/articles", tags=["Admin Articles"])


def _write_article_audit(
    db: Session,
    admin: User,
    action: str,
    article_id: str,
    detail: Optional[str] = None,
) -> None:
    """Write an audit log entry for admin/counselor article management actions."""
    entry = AuditLog(
        admin_id=admin.id,
        admin_email=admin.email,
        action=action,
        target_type="article",
        target_id=article_id,
        detail=detail,
    )
    db.add(entry)
    db.commit()

class ArticleCreate(BaseModel):
    title: str
    subtitle: Optional[str] = None
    category: str
    status: str = "published"
    is_featured: bool = False
    read_time: str = "5 min"
    author: str = "Kausap Guidance Team"
    author_role: str = "Mental Health Professional"
    image_url: Optional[str] = None
    theme_color_hex: str = "#0077B6"
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
    subtitle: Optional[str] = None
    category: str
    status: str
    is_featured: bool
    read_time: str
    author: str
    author_role: str
    image_url: Optional[str] = None
    theme_color_hex: str
    content: List[Dict]
    is_published: bool
    created_at: datetime
    updated_at: datetime
    reaction_counts: Dict[str, int] = {}
    user_reaction: Optional[str] = None

class ReactionPayload(BaseModel):
    emoji: str

def _format_article_read(article: Article, user_id: Optional[str] = None, db: Optional[Session] = None) -> ArticleRead:
    try:
        content = json.loads(article.content_json)
    except Exception:
        content = []

    try:
        reaction_counts = json.loads(article.reaction_counts_json)
    except Exception:
        reaction_counts = {}

    user_reaction = None
    if user_id and db:
        user_rx = db.exec(
            select(ArticleReaction).where(
                ArticleReaction.article_id == article.id,
                ArticleReaction.user_id == user_id
            )
        ).first()
        if user_rx:
            user_reaction = user_rx.emoji

    return ArticleRead(
        id=article.id,
        title=article.title,
        subtitle=article.subtitle,
        category=article.category,
        status=article.status,
        is_featured=article.is_featured,
        read_time=article.read_time,
        author=article.author,
        author_role=article.author_role,
        image_url=article.image_url,
        theme_color_hex=article.theme_color_hex,
        content=content,
        is_published=article.is_published,
        created_at=article.created_at,
        updated_at=article.updated_at,
        reaction_counts=reaction_counts,
        user_reaction=user_reaction,
    )

# ── Public Endpoints ─────────────────────────────────────────────────────────

@router.get("", response_model=List[ArticleRead])
def list_published_articles(
    session: Annotated[Session, Depends(get_session)],
    category: Optional[str] = None,
    current_user: Annotated[Optional[User], Depends(get_current_user_optional)] = None,
):
    """List all published psychoeducation articles."""
    query = select(Article).where(Article.is_published == True)
    if category and category.lower() != "all":
        query = query.where(Article.category == category)
    query = query.order_by(Article.created_at.desc())
    articles = session.exec(query).all()

    user_id = str(current_user.id) if current_user else None
    return [_format_article_read(a, user_id=user_id, db=session) for a in articles]

@router.get("/{article_id}", response_model=ArticleRead)
def get_article(
    article_id: str,
    session: Annotated[Session, Depends(get_session)],
    current_user: Annotated[Optional[User], Depends(get_current_user_optional)] = None,
):
    """Get single article by ID."""
    article = session.get(Article, article_id)
    if not article or not article.is_published:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Article not found")

    user_id = str(current_user.id) if current_user else None
    return _format_article_read(article, user_id=user_id, db=session)

@router.post("/{article_id}/react")
def react_to_article(
    article_id: str,
    payload: ReactionPayload,
    session: Annotated[Session, Depends(get_session)],
    current_user: Annotated[Optional[User], Depends(get_current_user_optional)] = None,
):
    """Add or change an emoji reaction to an article."""
    article = session.get(Article, article_id)
    if not article:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Article not found")

    allowed_emojis = ["💡", "❤️", "🙏", "🌿", "👏"]
    if payload.emoji not in allowed_emojis:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid reaction emoji")

    if current_user:
        user_id = str(current_user.id)
        existing = session.exec(
            select(ArticleReaction).where(
                ArticleReaction.article_id == article_id,
                ArticleReaction.user_id == user_id
            )
        ).first()

        try:
            counts = json.loads(article.reaction_counts_json)
        except Exception:
            counts = {}

        if existing:
            if existing.emoji == payload.emoji:
                session.delete(existing)
                counts[payload.emoji] = max(0, counts.get(payload.emoji, 1) - 1)
                article.reaction_counts_json = json.dumps(counts)
                session.add(article)
                session.commit()
                return {"status": "removed", "reaction_counts": counts, "user_reaction": None}
            else:
                old_emoji = existing.emoji
                counts[old_emoji] = max(0, counts.get(old_emoji, 1) - 1)
                counts[payload.emoji] = counts.get(payload.emoji, 0) + 1
                existing.emoji = payload.emoji
                article.reaction_counts_json = json.dumps(counts)
                session.add(existing)
                session.add(article)
                session.commit()
                return {"status": "updated", "reaction_counts": counts, "user_reaction": payload.emoji}
        else:
            new_rx = ArticleReaction(
                id=str(uuid.uuid4()),
                article_id=article_id,
                user_id=user_id,
                emoji=payload.emoji
            )
            counts[payload.emoji] = counts.get(payload.emoji, 0) + 1
            article.reaction_counts_json = json.dumps(counts)
            session.add(new_rx)
            session.add(article)
            session.commit()
            return {"status": "added", "reaction_counts": counts, "user_reaction": payload.emoji}

    try:
        counts = json.loads(article.reaction_counts_json)
    except Exception:
        counts = {}
    counts[payload.emoji] = counts.get(payload.emoji, 0) + 1
    article.reaction_counts_json = json.dumps(counts)
    session.add(article)
    session.commit()

    return {"status": "ok", "reaction_counts": counts}

# ── Admin & Counselor Management Endpoints ────────────────────────────────────

@admin_router.get("", response_model=List[ArticleRead])
def admin_list_all_articles(
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """List all articles including drafts and archived (Counselor or Admin)."""
    query = select(Article).order_by(Article.created_at.desc())
    articles = session.exec(query).all()
    return [_format_article_read(a) for a in articles]

@admin_router.post("", response_model=ArticleRead, status_code=status.HTTP_201_CREATED)
def admin_create_article(
    payload: ArticleCreate,
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Create and publish a new psychoeducation article (Counselor or Admin)."""
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

    _write_article_audit(session, admin, "article_published", article.id,
                         detail=f"Published: '{article.title}'")

    return _format_article_read(article)

@admin_router.put("/{article_id}", response_model=ArticleRead)
def admin_update_article(
    article_id: str,
    payload: ArticleUpdate,
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Update an existing psychoeducation article (Counselor or Admin)."""
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

    _write_article_audit(session, admin, "article_updated", article_id,
                         detail=f"Updated fields: {', '.join(update_data.keys())} on '{article.title}'")

    return _format_article_read(article)

@admin_router.patch("/{article_id}", response_model=ArticleRead)
def admin_patch_article(
    article_id: str,
    payload: ArticleUpdate,
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Partially update an article (Counselor or Admin)."""
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

    _write_article_audit(session, admin, "article_updated", article_id,
                         detail=f"Patched: {', '.join(update_data.keys())} on '{article.title}'")

    return _format_article_read(article)

@admin_router.delete("/{article_id}", status_code=status.HTTP_204_NO_CONTENT)
def admin_delete_article(
    article_id: str,
    admin: Annotated[User, Depends(get_current_counselor_or_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """Delete a psychoeducation article (Counselor or Admin)."""
    article = session.get(Article, article_id)
    if not article:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Article not found")

    title_snapshot = article.title
    session.delete(article)
    session.commit()

    _write_article_audit(session, admin, "article_deleted", article_id,
                         detail=f"Permanently deleted: '{title_snapshot}'")

    return None
