from datetime import datetime, timedelta, timezone
from typing import Annotated, Optional
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import Session, select, func

from app.database import get_session
from app.core.deps import get_current_user
from app.models.user import User
from app.models.mood import MoodEntry
from app.schemas.mood import MoodEntryCreate, MoodEntryRead, MoodEntryUpdate, MoodSummary

router = APIRouter(prefix="/mood", tags=["Mood"])


# ── helpers ──────────────────────────────────────────────────────────────────

def _own_entry_or_404(
    entry_id: uuid.UUID,
    current_user: User,
    session: Session,
) -> MoodEntry:
    """Fetch a MoodEntry and ensure it belongs to the current user."""
    entry = session.get(MoodEntry, entry_id)
    if entry is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mood entry not found")
    if entry.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your mood entry")
    return entry


# ── endpoints ─────────────────────────────────────────────────────────────────

@router.post("", response_model=MoodEntryRead, status_code=status.HTTP_201_CREATED)
def create_mood_entry(
    payload: MoodEntryCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Create a new mood entry for the currently authenticated user."""
    if not (1 <= payload.mood_level <= 5):
        raise HTTPException(status_code=400, detail="mood_level must be between 1 and 5")

    entry = MoodEntry(
        user_id=current_user.id,
        mood_level=payload.mood_level,
        note=payload.note,
    )
    session.add(entry)
    session.commit()
    session.refresh(entry)
    return entry


@router.get("/summary", response_model=MoodSummary)
def mood_summary(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    Return average mood + entry count for the last 7 and 30 days.
    This endpoint MUST be declared before GET /{entry_id} to avoid
    FastAPI treating 'summary' as a UUID.
    """
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    cutoff_7d = now - timedelta(days=7)
    cutoff_30d = now - timedelta(days=30)

    def _stats(cutoff: datetime):
        rows = session.exec(
            select(MoodEntry).where(
                MoodEntry.user_id == current_user.id,
                MoodEntry.created_at >= cutoff,
            )
        ).all()
        count = len(rows)
        avg = round(sum(r.mood_level for r in rows) / count, 2) if count else None
        return avg, count

    avg_7d, count_7d = _stats(cutoff_7d)
    avg_30d, count_30d = _stats(cutoff_30d)

    return MoodSummary(
        avg_mood_7d=avg_7d,
        count_7d=count_7d,
        avg_mood_30d=avg_30d,
        count_30d=count_30d,
    )


@router.get("", response_model=list[MoodEntryRead])
def list_mood_entries(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
    from_date: Annotated[Optional[datetime], Query(alias="from")] = None,
    to_date: Annotated[Optional[datetime], Query(alias="to")] = None,
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    """List the authenticated user's mood entries, newest first. Supports date range + pagination."""
    query = select(MoodEntry).where(MoodEntry.user_id == current_user.id)
    if from_date:
        query = query.where(MoodEntry.created_at >= from_date)
    if to_date:
        query = query.where(MoodEntry.created_at <= to_date)
    query = query.order_by(MoodEntry.created_at.desc()).offset(offset).limit(limit)
    return session.exec(query).all()


@router.get("/{entry_id}", response_model=MoodEntryRead)
def get_mood_entry(
    entry_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get a single mood entry. Returns 403 if it belongs to another user."""
    return _own_entry_or_404(entry_id, current_user, session)


@router.patch("/{entry_id}", response_model=MoodEntryRead)
def update_mood_entry(
    entry_id: uuid.UUID,
    payload: MoodEntryUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Update mood_level or note on an entry that belongs to the current user."""
    entry = _own_entry_or_404(entry_id, current_user, session)

    if payload.mood_level is not None:
        if not (1 <= payload.mood_level <= 5):
            raise HTTPException(status_code=400, detail="mood_level must be between 1 and 5")
        entry.mood_level = payload.mood_level

    if payload.note is not None:
        entry.note = payload.note

    session.add(entry)
    session.commit()
    session.refresh(entry)
    return entry


@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_mood_entry(
    entry_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Delete an entry that belongs to the current user."""
    entry = _own_entry_or_404(entry_id, current_user, session)
    session.delete(entry)
    session.commit()
