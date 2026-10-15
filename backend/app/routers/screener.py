"""
screener.py
-----------
Counselor escalation for the standardized PHQ-9 / GAD-7 self-assessments.

The mobile app scores the questionnaires locally. When a result meets a
safety rule it calls POST /screeners/flag so the case shows up in the
counselor triage queue (the same queue used for AI-chat risk flags).

Safety rules (kept in sync with the mobile app):
  * PHQ-9 item 9 (thoughts of self-harm) answered above 0   -> flag
  * PHQ-9 total score >= 15 (moderately severe / severe)    -> flag
  * GAD-7 total score >= 15 (severe anxiety)                -> flag

These are screening results only, not a diagnosis.
"""
from typing import Annotated, List, Optional
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlmodel import Session, select

from app.database import get_session
from app.models.user import User
from app.models.chat import ChatSession, ChatMessage
from app.core.deps import get_current_user

router = APIRouter(prefix="/screeners", tags=["Screeners"])

PHQ9_FLAG_SCORE = 15
GAD7_FLAG_SCORE = 15
_DEDUPE_HOURS = 6
_ANSWER_LABELS = {1: "several days", 2: "more than half the days", 3: "nearly every day"}


class ScreenerFlagRequest(BaseModel):
    screener: str = Field(description="'phq9' or 'gad7'")
    score: int = Field(ge=0, le=27)
    severity: Optional[str] = None
    # Individual answers (0-3) in question order. Needed for PHQ-9 item 9.
    answers: List[int] = Field(default_factory=list)


class ScreenerFlagResponse(BaseModel):
    flagged: bool
    reasons: List[str] = []
    message_id: Optional[str] = None


def evaluate_flag_reasons(screener: str, score: int, answers: List[int]) -> List[str]:
    """Return the list of safety rules triggered by this result (empty = no flag)."""
    kind = screener.lower()
    reasons: List[str] = []
    if "phq" in kind:
        if len(answers) >= 9 and answers[8] > 0:
            reasons.append("PHQ-9 item 9: thoughts of self-harm reported "
                           f"({_ANSWER_LABELS.get(answers[8], 'yes')})")
        if score >= PHQ9_FLAG_SCORE:
            reasons.append(f"PHQ-9 total score {score}/27 is in the moderately severe or severe range")
    elif "gad" in kind:
        if score >= GAD7_FLAG_SCORE:
            reasons.append(f"GAD-7 total score {score}/21 is in the severe range")
    return reasons


@router.post("/flag", response_model=ScreenerFlagResponse)
@router.post("/flag/", response_model=ScreenerFlagResponse)
def flag_screener_result(
    payload: ScreenerFlagRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    Re-evaluates the safety rules server-side (the client is never trusted to decide)
    and, if triggered, creates a risk-flagged entry in the counselor triage queue.
    """
    kind = payload.screener.lower()
    test_label = "PHQ-9" if "phq" in kind else ("GAD-7" if "gad" in kind else None)
    if test_label is None:
        return ScreenerFlagResponse(flagged=False)

    reasons = evaluate_flag_reasons(kind, payload.score, payload.answers)
    if not reasons:
        return ScreenerFlagResponse(flagged=False)

    max_score = 27 if test_label == "PHQ-9" else 21
    content = (
        f"[Screener Alert] {test_label} self-assessment flagged for counselor review. "
        f"Score {payload.score}/{max_score}"
        + (f" ({payload.severity})" if payload.severity else "")
        + ". Reason: " + "; ".join(reasons)
        + ". This is a screening result, not a diagnosis."
    )

    # Avoid flooding the triage queue with identical alerts from repeated retakes.
    since = datetime.utcnow() - timedelta(hours=_DEDUPE_HOURS)
    existing = session.exec(
        select(ChatMessage)
        .join(ChatSession, ChatMessage.session_id == ChatSession.id)
        .where(
            ChatSession.user_id == current_user.id,
            ChatMessage.risk_flag == True,  # noqa: E712
            ChatMessage.content == content,
            ChatMessage.created_at >= since,
        )
    ).first()
    if existing:
        return ScreenerFlagResponse(flagged=True, reasons=reasons, message_id=str(existing.id))

    chat_session = ChatSession(user_id=current_user.id, topic=f"{test_label} Screener Alert")
    session.add(chat_session)
    session.commit()
    session.refresh(chat_session)

    msg = ChatMessage(
        session_id=chat_session.id,
        role="user",
        content=content,
        risk_flag=True,
    )
    session.add(msg)
    session.commit()
    session.refresh(msg)

    return ScreenerFlagResponse(flagged=True, reasons=reasons, message_id=str(msg.id))
