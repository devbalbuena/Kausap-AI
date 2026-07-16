from typing import Annotated, List
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.database import get_session
from app.core.deps import get_current_user
from app.models.user import User
from app.models.chat import ChatSession, ChatMessage
from app.schemas.chat import ChatMessageCreate, ChatMessageRead, ChatSessionRead
from app.core.risk_detection import check_for_risk
from app.core.ai_provider import chat_completion

router = APIRouter(prefix="/chat", tags=["Chat"])

SAFETY_MESSAGE = """I'm really glad you reached out, and I want you to know you don't have to go through this alone. What you're feeling matters, and there are people ready to help right now.

You can call the National Center for Mental Health (NCMH) Crisis Hotline anytime, 24/7, for free: 1553 (or 0917-899-8727). 

You can also use the Doctor Referral feature in this app to connect with a mental health professional.

If you're in immediate danger, please contact emergency services or go to the nearest hospital right away."""


def _get_own_session(
    session_id: uuid.UUID,
    current_user: User,
    db: Session,
) -> ChatSession:
    """Fetch a ChatSession and ensure it belongs to the current user."""
    chat_session = db.get(ChatSession, session_id)
    if chat_session is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Chat session not found")
    if chat_session.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your chat session")
    return chat_session


@router.post("/sessions", response_model=ChatSessionRead, status_code=status.HTTP_201_CREATED)
def create_session(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """Create a new chat session for the logged-in user."""
    chat_session = ChatSession(user_id=current_user.id)
    db.add(chat_session)
    db.commit()
    db.refresh(chat_session)
    return chat_session


@router.get("/sessions", response_model=List[ChatSessionRead])
def list_sessions(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """List the logged-in user's past sessions."""
    return db.exec(
        select(ChatSession)
        .where(ChatSession.user_id == current_user.id)
        .order_by(ChatSession.created_at.desc())
    ).all()


@router.get("/sessions/{session_id}", response_model=ChatSessionRead)
def get_session_details(
    session_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """Get a specific session with its full message history."""
    return _get_own_session(session_id, current_user, db)


@router.post("/sessions/{session_id}/messages", response_model=ChatMessageRead)
async def post_message(
    session_id: uuid.UUID,
    payload: ChatMessageCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """Post a new message to a chat session, check for risk, and return the AI's reply."""
    chat_session = _get_own_session(session_id, current_user, db)

    # 1. Check for risk in user message
    is_risk = check_for_risk(payload.content)

    # 2. Save user message to DB
    user_msg = ChatMessage(
        session_id=chat_session.id,
        role="user",
        content=payload.content,
        risk_flag=is_risk
    )
    db.add(user_msg)
    db.commit()

    # 3. Handle response based on risk detection
    if is_risk:
        # Pre-written safety message response
        ai_reply_content = SAFETY_MESSAGE
        ai_risk_flag = True
    else:
        # Normal AI conversation flow
        # Build message history for the LLM context
        # We need to fetch previous messages in the session, sorted by created_at
        db.refresh(chat_session) # Ensure messages are loaded
        # Sort messages by created_at to maintain chronological order
        sorted_messages = sorted(chat_session.messages, key=lambda m: m.created_at)
        
        # Prepare context for OpenAI
        # We can add a system prompt at the beginning
        llm_messages = [
            {"role": "system", "content": "You are Kausap AI, an empathetic and supportive mental health chatbot for users in the Philippines. You are a conversational partner. Be warm, non-judgmental, and helpful."}
        ]
        
        for msg in sorted_messages:
            llm_messages.append({"role": msg.role, "content": msg.content})

        try:
            ai_reply_content = await chat_completion(llm_messages)
            ai_risk_flag = False
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"AI provider error: {str(e)}")

    # 4. Save Assistant reply
    ai_msg = ChatMessage(
        session_id=chat_session.id,
        role="assistant",
        content=ai_reply_content,
        risk_flag=ai_risk_flag
    )
    db.add(ai_msg)
    db.commit()
    db.refresh(ai_msg)

    # 5. Always return the assistant's message in the response
    return ai_msg
