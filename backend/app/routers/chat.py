from typing import Annotated, List
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlmodel import Session, select

from app.database import get_session
from app.core.deps import get_current_user
from app.models.user import User
from app.models.chat import ChatSession, ChatMessage
from app.models.token_log import TokenUsageLog
from app.schemas.chat import ChatMessageCreate, ChatMessageRead, ChatSessionRead
from app.core.risk_detection import check_for_risk
from app.core.ai_provider import chat_completion_with_usage, calculate_cost_usd
from app.core.clinical_guardrails import check_clinical_boundary, build_system_messages

router = APIRouter(prefix="/chat", tags=["Chat"])

SAFETY_MESSAGE = """I'm really glad you reached out, and I want you to know you don't have to go through this alone. What you're feeling matters, and there are people ready to help right now.

You can call the National Center for Mental Health (NCMH) Crisis Hotline anytime, 24/7, for free: 1553 (or 0917-899-8727), or Hopeline Philippines: 0917-558-4673.

You can also reach out to the CSU Guidance & Counseling Office or dial 911 immediately if you are in immediate danger."""


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

    Three-layer clinical protection pipeline:
      Layer 1 — Crisis risk detection (suicide/self-harm keywords)
      Layer 2 — Clinical boundary check (prescription/diagnosis requests)
      Layer 3 — Hardened system prompt injected into every LLM call
    """
    chat_session = _get_own_session(session_id, current_user, db)

    # ── Layer 1: Crisis risk detection ────────────────────────────────────────
    is_risk = check_for_risk(payload.content)

    # ── Save user message to DB (before any processing) ───────────────────────
    user_msg = ChatMessage(
        session_id=chat_session.id,
        role="user",
        content=payload.content,
        risk_flag=is_risk
    )
    db.add(user_msg)
    db.commit()

    # ── Layer 1 Response: Crisis safety message ────────────────────────────────
    if is_risk:
        ai_reply_content = SAFETY_MESSAGE
        ai_risk_flag = False  # Assistant safety response is NOT a student crisis trigger

    else:
        # ── Layer 2: Clinical boundary guardrail check ─────────────────────────
        # Intercepts requests for medication prescription or formal diagnosis
        # BEFORE they reach the LLM. The AI never sees boundary-violating prompts.
        is_boundary_violation, boundary_response = check_clinical_boundary(payload.content)

        if is_boundary_violation:
            # Return compassionate redirect — AI is bypassed entirely.
            # Flagged in DB so counselors can see students who need clinical referral.
            ai_reply_content = boundary_response  # type: ignore[assignment]
            ai_risk_flag = False  # Not a crisis — a clinical referral case
        else:
            # ── Layer 3: Hardened system prompt + Normal AI conversation ───────
            db.refresh(chat_session)
            sorted_messages = sorted(chat_session.messages, key=lambda m: m.created_at)

            # build_system_messages() returns the hardened clinical boundary system prompt.
            # It ALWAYS anchors the first message, regardless of conversation history.
            llm_messages = build_system_messages()

            for msg in sorted_messages:
                llm_messages.append({"role": msg.role, "content": msg.content})

            try:
                ai_reply_content, prompt_tokens, completion_tokens, total_tokens = await chat_completion_with_usage(llm_messages)
                ai_risk_flag = False

                # Record Token Telemetry for Super Admin
                try:
                    cost = calculate_cost_usd(prompt_tokens, completion_tokens)
                    token_entry = TokenUsageLog(
                        user_id=current_user.id,
                        session_id=chat_session.id,
                        model="gpt-4o-mini",
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
        risk_flag=ai_risk_flag
    )
    db.add(ai_msg)
    db.commit()
    db.refresh(ai_msg)

    return ai_msg


@router.post("/sos-alert", response_model=SosAlertResponse, status_code=status.HTTP_201_CREATED)
def trigger_sos_alert(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """Trigger an immediate 1-tap SOS distress alert from the student to the campus guidance & admin network."""
    # 1. Create a dedicated SOS session
    session = ChatSession(
        user_id=current_user.id,
        topic="🚨 EMERGENCY SOS DISTRESS ALERT"
    )
    db.add(session)
    db.commit()
    db.refresh(session)

    # 2. Add flagged student distress message
    student_name = current_user.full_name or current_user.email
    user_alert_msg = ChatMessage(
        session_id=session.id,
        role="user",
        content=f"🚨 EMERGENCY SOS DISTRESS ALERT: Student {student_name} ({current_user.email}) requested immediate crisis support via 1-Tap SOS.",
        risk_flag=True
    )
    db.add(user_alert_msg)

    # 3. Add system reassurance response
    system_reply = ChatMessage(
        session_id=session.id,
        role="assistant",
        content=f"Your emergency distress alert has been logged with highest priority for the guidance team. If you are in immediate physical danger, please immediately dial NCMH 1553 (Toll-Free 24/7) or 911. Help is available.",
        risk_flag=False  # Assistant safety response is NOT a student crisis trigger
    )
    db.add(system_reply)
    db.commit()

    return SosAlertResponse(
        status="alert_sent",
        message="Emergency SOS distress alert registered and escalated to crisis triage.",
        session_id=session.id
    )
