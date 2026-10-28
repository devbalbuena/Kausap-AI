from typing import Annotated, List, Optional
import uuid
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from app.database import get_session
from app.models.user import User
from app.models.journal import JournalEntry
from app.schemas.journal import JournalCreate, JournalRead, JournalUpdate
from app.core.deps import get_current_user

router = APIRouter(prefix="/journal", tags=["Daily Journal"])


def _get_pht_today_str() -> str:
    """Return today's date in Philippine/Singapore Standard Time (UTC+8)."""
    pht_now = datetime.now(timezone.utc) + timedelta(hours=8)
    return pht_now.strftime("%Y-%m-%d")


@router.get("", response_model=List[JournalRead])
@router.get("/", response_model=List[JournalRead])
def get_all_journals(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get all journal entries for the current student, sorted by newest first."""
    entries = session.exec(
        select(JournalEntry)
        .where(JournalEntry.user_id == current_user.id)
        .order_by(JournalEntry.created_at.desc())
    ).all()
    return entries


@router.get("/today", response_model=List[JournalRead])
@router.get("/today/", response_model=List[JournalRead])
def get_today_journals(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Get all journal entries written today."""
    today_str = _get_pht_today_str()
    entries = session.exec(
        select(JournalEntry)
        .where(JournalEntry.user_id == current_user.id, JournalEntry.entry_date == today_str)
        .order_by(JournalEntry.created_at.desc())
    ).all()
    return entries


@router.post("", response_model=JournalRead, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=JournalRead, status_code=status.HTTP_201_CREATED)
def create_journal_entry(
    payload: JournalCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Create a new distinct journal entry (supports multiple entries per day)."""
    if not payload.content or not payload.content.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Journal reflection cannot be empty or whitespace only.",
        )

    cleaned_content = payload.content.strip()
    cleaned_title = payload.title.strip() if payload.title and payload.title.strip() else "Daily Reflection"
    entry_date = payload.entry_date or _get_pht_today_str()
    now_utc = datetime.now(timezone.utc).replace(tzinfo=None)

    new_entry = JournalEntry(
        user_id=current_user.id,
        title=cleaned_title,
        content=cleaned_content,
        entry_date=entry_date,
        mood_tag=payload.mood_tag.strip() if payload.mood_tag and payload.mood_tag.strip() else None,
        prompt=payload.prompt.strip() if payload.prompt and payload.prompt.strip() else None,
        created_at=now_utc,
        updated_at=now_utc,
    )
    session.add(new_entry)
    session.commit()
    session.refresh(new_entry)
    return new_entry


@router.put("/{entry_id}", response_model=JournalRead)
@router.put("/{entry_id}/", response_model=JournalRead)
def update_journal_entry(
    entry_id: uuid.UUID,
    payload: JournalUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Edit an existing journal entry."""
    entry = session.exec(
        select(JournalEntry)
        .where(JournalEntry.id == entry_id, JournalEntry.user_id == current_user.id)
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Journal entry not found")

    if payload.content is not None:
        if not payload.content.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Journal reflection cannot be empty or whitespace only.",
            )
        payload.content = payload.content.strip()

    if payload.title is not None:
        payload.title = payload.title.strip() or "Daily Reflection"

    if payload.mood_tag is not None:
        payload.mood_tag = payload.mood_tag.strip() if payload.mood_tag.strip() else None

    if payload.prompt is not None:
        payload.prompt = payload.prompt.strip() if payload.prompt.strip() else None

    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(entry, key, value)
    entry.updated_at = datetime.now(timezone.utc).replace(tzinfo=None)

    session.add(entry)
    session.commit()
    session.refresh(entry)
    return entry


@router.delete("/{entry_id}", status_code=status.HTTP_200_OK)
@router.delete("/{entry_id}/", status_code=status.HTTP_200_OK)
def delete_journal(
    entry_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """Delete a specific journal entry."""
    entry = session.exec(
        select(JournalEntry)
        .where(JournalEntry.id == entry_id, JournalEntry.user_id == current_user.id)
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Journal entry not found")
    session.delete(entry)
    session.commit()
    return {"deleted": True, "id": str(entry_id)}
