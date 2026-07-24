from typing import Annotated, List
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select, or_, and_
from app.database import get_session
from app.models.user import User
from app.models.direct_message import DirectMessage
from app.schemas.direct_message import DirectMessageCreate, DirectMessageRead
from app.core.deps import get_current_user

router = APIRouter(prefix="/direct-messages", tags=["Direct Messages"])

@router.get("/{other_user_id}", response_model=List[DirectMessageRead])
def get_messages(
    other_user_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)]
):
    """Get chat history between the current user and another user."""
    # Verify other user exists
    other_user = session.exec(select(User).where(User.id == other_user_id)).first()
    if not other_user:
        raise HTTPException(status_code=404, detail="User not found")
        
    messages = session.exec(
        select(DirectMessage).where(
            or_(
                and_(DirectMessage.sender_id == current_user.id, DirectMessage.receiver_id == other_user_id),
                and_(DirectMessage.sender_id == other_user_id, DirectMessage.receiver_id == current_user.id)
            )
        ).order_by(DirectMessage.created_at.asc())
    ).all()
    
    # Mark as read (if receiver is current user and not read)
    unread_messages = [msg for msg in messages if msg.receiver_id == current_user.id and not msg.is_read]
    for msg in unread_messages:
        msg.is_read = True
        session.add(msg)
    if unread_messages:
        session.commit()
    
    return messages

@router.post("/", response_model=DirectMessageRead)
def send_message(
    payload: DirectMessageCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)]
):
    """Send a direct message to another user."""
    # Verify receiver exists
    receiver = session.exec(select(User).where(User.id == payload.receiver_id)).first()
    if not receiver:
        raise HTTPException(status_code=404, detail="Receiver not found")
        
    db_message = DirectMessage(
        sender_id=current_user.id,
        receiver_id=payload.receiver_id,
        content=payload.content
    )
    
    session.add(db_message)
    session.commit()
    session.refresh(db_message)
    
    return db_message
