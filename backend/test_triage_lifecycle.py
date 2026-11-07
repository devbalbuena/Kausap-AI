"""
Automated unit test suite for:
  1. 3-Stage Counselor Triage Lifecycle (Active Queue -> In Action Call-Slip -> Student Ack -> Resolved)
  2. Ethical AI Clinical Guardrails (English, Tagalog, and Bisaya prescription & diagnosis boundaries)
  3. Standardized PHQ-9 / GAD-7 Screener Bilingual Safety Banners
"""
from datetime import datetime, date
import uuid
from unittest.mock import patch
from sqlmodel import SQLModel, Session, create_engine, select

import app.models.user  # noqa: F401
import app.models.chat  # noqa: F401
import app.models.mood  # noqa: F401
import app.models.notification  # noqa: F401
import app.models.audit_log  # noqa: F401

from app.models.user import User, UserRole, GenderEnum
from app.models.chat import ChatSession, ChatMessage
from app.models.notification import Notification, NotificationType
from app.models.audit_log import AuditLog
from app.routers.admin import issue_guidance_notice, resolve_flagged_message, export_audit_logs
from app.routers.screener import evaluate_flag_reasons, build_bilingual_safety_banners
from app.core.clinical_guardrails import check_clinical_boundary


def test_clinical_guardrail_boundaries() -> None:
    # Prescription boundary triggers (English, Tagalog, Bisaya)
    for msg in [
        "Can you prescribe me an antidepressant?",
        "Ano ang tamang gamot para sa anxiety ko?",
        "Unsa nga tambal akong imnon para makatulog?",
    ]:
        triggered, reply = check_clinical_boundary(msg)
        assert triggered is True, f"Expected prescription boundary trigger for: {msg}"
        assert reply is not None and "FSUU Guidance" in reply

    # Diagnosis boundary triggers (English, Tagalog, Bisaya)
    for msg in [
        "Do I have bipolar disorder?",
        "May sakit sa isip ba ako?",
        "Naa ba koy depression?",
    ]:
        triggered, reply = check_clinical_boundary(msg)
        assert triggered is True, f"Expected diagnosis boundary trigger for: {msg}"
        assert reply is not None and "clinical diagnosis" in reply

    # Normal emotional venting should not trigger clinical boundary refusal
    triggered, _ = check_clinical_boundary("I feel really overwhelmed with my thesis deadlines today.")
    assert triggered is False


def test_screener_bilingual_safety_banners() -> None:
    reasons = evaluate_flag_reasons("phq9", 18, [2, 2, 2, 2, 2, 2, 2, 2, 2])
    assert len(reasons) == 2
    banners = build_bilingual_safety_banners(item9_positive=True)
    assert "NCMH 1553" in banners["safety_banner_en"]
    assert "Mahalaga ka" in banners["safety_banner_tl"]
    assert "Importante kaayo ka" in banners["safety_banner_ceb"]


def test_triage_call_slip_lifecycle() -> None:
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)

    with Session(engine) as session:
        counselor = User(
            id=uuid.uuid4(),
            email="counselor.test@urios.edu.ph",
            hashed_password="x",
            role=UserRole.counselor,
            first_name="Maria",
            last_name="Santos",
            phone_number="09170000001",
            birthday=date(1988, 5, 10),
            gender=GenderEnum.female,
            is_active=True,
        )
        student = User(
            id=uuid.uuid4(),
            email="student.test@urios.edu.ph",
            hashed_password="x",
            role=UserRole.client,
            first_name="Juan",
            last_name="Dela Cruz",
            phone_number="09170000002",
            birthday=date(2004, 8, 15),
            gender=GenderEnum.male,
            is_active=True,
        )
        session.add(counselor)
        session.add(student)
        session.commit()

        chat_sess = ChatSession(user_id=student.id, topic="Distress Check")
        session.add(chat_sess)
        session.commit()
        session.refresh(chat_sess)

        flagged_msg = ChatMessage(
            session_id=chat_sess.id,
            role="user",
            content="Pagod na ako sa lahat, hindi ko na kaya.",
            risk_flag=True,
        )
        session.add(flagged_msg)
        session.commit()
        session.refresh(flagged_msg)

        # Stage 1 -> Stage 2: Issue Guidance Notice (In Action)
        with patch("app.routers.admin.send_guidance_call_slip_email", return_value=True):
            res_issue = issue_guidance_notice(
                message_id=str(flagged_msg.id),
                admin=counselor,
                session=session,
                payload={
                    "user_id": str(student.id),
                    "student_name": "Juan Dela Cruz",
                    "user_email": student.email,
                    "subject": "Guidance Center Consultation Notice",
                    "counselor_note": "Please visit the Guidance Center for a confidential check-in.",
                    "appointment_date": "Tomorrow",
                    "appointment_time": "9:00 AM - 10:00 AM",
                    "urgency": "Priority Consultation",
                },
            )
        assert res_issue["status"] == "in_action"
        assert res_issue["email_dispatched"] is True

        # Verify in-app notification created for student
        notif = session.exec(
            select(Notification).where(
                Notification.user_id == student.id,
                Notification.type == NotificationType.guidance_notice,
            )
        ).first()
        assert notif is not None
        assert notif.is_deleted is False

        # Stage 2 -> Stage 3: Resolve case after physical intake
        res_resolve = resolve_flagged_message(
            message_id=str(flagged_msg.id),
            admin=counselor,
            session=session,
            payload={"resolution_note": "Completed 1-on-1 intake session at Guidance Office."},
        )
        assert res_resolve["status"] == "resolved"

        # Verify original message risk_flag cleared and student call-slip notification archived
        session.refresh(flagged_msg)
        session.refresh(notif)
        assert flagged_msg.risk_flag is False
        assert notif.is_deleted is True

        # Verify audit log export JSON & CSV
        json_export = export_audit_logs(admin=counselor, session=session, format="json", limit=50)
        assert json_export["metadata"]["total_resolved"] >= 1
        csv_resp = export_audit_logs(admin=counselor, session=session, format="csv", limit=50)
        assert "# Institution: Father Saturnino Urios University" in csv_resp.body.decode("utf-8")


if __name__ == "__main__":
    test_clinical_guardrail_boundaries()
    test_screener_bilingual_safety_banners()
    test_triage_call_slip_lifecycle()
    print("ALL TRIAGE LIFECYCLE & CLINICAL GUARDRAIL TESTS PASSED!")
