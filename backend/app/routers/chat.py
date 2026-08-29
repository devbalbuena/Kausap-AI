from typing import Annotated, List, Optional
import uuid
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlmodel import Session, select

from app.database import get_session
from app.core.deps import get_current_user
from app.models.user import User
from app.models.chat import ChatSession, ChatMessage
from app.models.mood import MoodEntry
from app.models.token_log import TokenUsageLog
from app.schemas.chat import ChatMessageCreate, ChatMessageRead, ChatSessionRead
from app.core.risk_detection import check_for_risk
from app.core.ai_provider import chat_completion_with_usage, calculate_cost_usd
from app.core.clinical_guardrails import check_clinical_boundary, build_system_messages, get_persona_temperature
from app.core.config import settings

router = APIRouter(prefix="/chat", tags=["Chat"])

SAFETY_MESSAGE = """I'm really glad you reached out, and I want you to know you don't have to go through this alone. What you're feeling matters, and there are caring people ready to support you right now.

You can call the National Center for Mental Health (NCMH) Crisis Hotline anytime, 24/7, for free:
📞 **1553** (or 0917-899-8727)
💬 **Hopeline Philippines**: 0917-558-4673

You can also connect directly with the **FSUU Guidance & Counseling Office** or dial 911 if you are in immediate danger. Please stay safe — your life is important. 💙"""


class SosAlertResponse(BaseModel):
    status: str
    message: str
    session_id: uuid.UUID


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
    """
    Post a new message to a chat session and return the AI's reply.

    Pipeline:
      1. Crisis risk detection (suicide/self-harm keywords)
      2. Rate limiting check (protect tokens & encourage healthy student pacing)
      3. Clinical boundary check (medication/diagnosis requests)
      4. Hardened system prompt with Carl Rogers Person-Centered Empathy & mood context
    """
    chat_session = _get_own_session(session_id, current_user, db)

    # ── Layer 1: Crisis risk detection ────────────────────────────────────────
    is_risk = check_for_risk(payload.content)

    # ── Save user message to DB ───────────────────────────────────────────────
    user_msg = ChatMessage(
        session_id=chat_session.id,
        role="user",
        content=payload.content,
        risk_flag=is_risk,
    )
    db.add(user_msg)
    db.commit()

    if is_risk:
        ai_reply_content = SAFETY_MESSAGE
        ai_risk_flag = False

    else:
        # ── Rate Limiting Check (Token & Pacing Protection) ───────────────────
        one_hour_ago = datetime.now(timezone.utc) - timedelta(hours=1)
        recent_msgs = db.exec(
            select(ChatMessage)
            .where(ChatMessage.session_id == chat_session.id)
            .where(ChatMessage.role == "user")
            .where(ChatMessage.created_at >= one_hour_ago)
        ).all()

        if len(recent_msgs) > settings.RATE_LIMIT_MESSAGES_PER_HOUR:
            student_name = current_user.first_name or current_user.full_name or "kaibigan"
            ai_reply_content = (
                f"Pahinga muna tayo nang sandali, {student_name}. 💙\n\n"
                "Nakapagbahagi ka na ng maraming saloobin ngayong oras na ito. "
                "Subukan nating uminom ng kaunting tubig, mag-relax, at magpahinga ng 10-15 minuto. "
                "Nandito pa rin ako pagbalik mo para ipagpatuloy ang ating kwentuhan!"
            )
            ai_risk_flag = False
        else:
            # ── Layer 2: Clinical boundary guardrail check ─────────────────────
            is_boundary_violation, boundary_response = check_clinical_boundary(payload.content)

            if is_boundary_violation:
                ai_reply_content = boundary_response or "Please connect with a healthcare professional."
                ai_risk_flag = False
            else:
                # ── Layer 3: Empathy Engine + Gemini 2.5 LLM Generation ─────────
                db.refresh(chat_session)
                sorted_messages = sorted(chat_session.messages, key=lambda m: m.created_at)

                # Fetch today's mood entry for context
                today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
                today_mood_entry = db.exec(
                    select(MoodEntry)
                    .where(MoodEntry.user_id == current_user.id)
                    .where(MoodEntry.created_at >= today_start)
                    .order_by(MoodEntry.created_at.desc())
                ).first()
                mood_level = today_mood_entry.mood_level if today_mood_entry else None

                # Build student cultural profile context
                cultural_parts = []
                if current_user.full_name:
                    cultural_parts.append(f"Full Name: {current_user.full_name}")
                if getattr(current_user, "department", None):
                    cultural_parts.append(f"University Program: {current_user.department}")
                if getattr(current_user, "year_level", None):
                    cultural_parts.append(f"Year Level: {current_user.year_level}")
                if getattr(current_user, "hobbies", None):
                    cultural_parts.append(f"Coping Outlets: {current_user.hobbies}")

                context_str = ", ".join(cultural_parts) if cultural_parts else None

                student_display_name = current_user.first_name or (
                    current_user.full_name.split()[0] if current_user.full_name else None
                )

                # Generate system prompt with Person-Centered Empathy & persona
                active_persona = payload.persona or "buddy"
                llm_messages = build_system_messages(
                    user_context=context_str,
                    persona=active_persona,
                    student_name=student_display_name,
                    mood_level=mood_level,
                    custom_system_prompt=payload.custom_system_prompt,
                )

                # Per-persona temperature tuning
                persona_temperature = get_persona_temperature(active_persona)

                # Append recent messages (keep last 12 turns for token efficiency)
                recent_history = sorted_messages[-12:]
                for msg in recent_history:
                    llm_messages.append({"role": msg.role, "content": msg.content})

                try:
                    ai_reply_content, prompt_tokens, completion_tokens, total_tokens = await chat_completion_with_usage(
                        llm_messages, max_tokens=settings.DEFAULT_MAX_TOKENS, temperature=persona_temperature
                    )
                    ai_risk_flag = False

                    # Record Token Telemetry for Admin
                    try:
                        cost = calculate_cost_usd(prompt_tokens, completion_tokens)
                        token_entry = TokenUsageLog(
                            user_id=current_user.id,
                            session_id=chat_session.id,
                            model="gemini-2.5-flash",
                            prompt_tokens=prompt_tokens,
                            completion_tokens=completion_tokens,
                            total_tokens=total_tokens,
                            estimated_cost_usd=cost,
                        )
                        db.add(token_entry)
                        db.commit()
                    except Exception:
                        pass
                except Exception as e:
                    raise HTTPException(status_code=500, detail=f"AI provider error: {str(e)}")

    # ── Save Assistant reply to DB ─────────────────────────────────────────────
    ai_msg = ChatMessage(
        session_id=chat_session.id,
        role="assistant",
        content=ai_reply_content,
        risk_flag=ai_risk_flag,
    )
    db.add(ai_msg)
    db.commit()
    db.refresh(ai_msg)
    return ai_msg


@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_session(
    session_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """Delete a chat session and all its messages."""
    chat_session = _get_own_session(session_id, current_user, db)
    db.delete(chat_session)
    db.commit()
    return None
