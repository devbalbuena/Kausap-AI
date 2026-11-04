"""
test_red_alert_counselor.py
---------------------------
Verifies the 3-day Red Alert escalation to counselors (isolated temporary SQLite database;
the real/Neon database configured in .env is never touched).
Run:  python test_red_alert_counselor.py
"""

import os
import sys
import tempfile
import uuid
from datetime import date, datetime, timedelta, timezone

# Force an isolated throwaway database BEFORE the app modules are imported.
_tmp_db = os.path.join(tempfile.mkdtemp(prefix="kausap_red_alert_"), "test.db")
os.environ["DATABASE_URL"] = f"sqlite:///{_tmp_db}"
os.environ["DATABASE_POOL_URL"] = ""

from sqlmodel import Session, SQLModel, select  # noqa: E402

from app.database import engine  # noqa: E402
from app.models.mood import MoodEntry  # noqa: E402
from app.models.notification import Notification, RED_ALERT_TITLE  # noqa: E402
from app.models.user import GenderEnum, User, UserRole  # noqa: E402
from app.routers.mood import create_mood_entry  # noqa: E402
from app.routers.notification import _ensure_daily_notifications  # noqa: E402
from app.schemas.mood import MoodEntryCreate  # noqa: E402

errors = []


def check(condition, msg):
    if condition:
        print(f"  PASS: {msg}")
    else:
        print(f"  FAIL: {msg}")
        errors.append(msg)


def make_user(session, email, role, first="Test", last="User", active=True):
    user = User(
        id=uuid.uuid4(),
        email=email,
        hashed_password="x",
        role=role,
        is_active=active,
        first_name=first,
        last_name=last,
        phone_number="09123456789",
        birthday=date(2003, 1, 1),
        gender=GenderEnum.prefer_not_to_say,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


def add_past_mood(session, user, days_ago, level):
    session.add(
        MoodEntry(
            user_id=user.id,
            mood_level=level,
            created_at=datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(days=days_ago),
        )
    )
    session.commit()


def red_alerts_for(session, user):
    return session.exec(
        select(Notification).where(
            Notification.user_id == user.id, Notification.title == RED_ALERT_TITLE
        )
    ).all()


SQLModel.metadata.create_all(engine)

with Session(engine) as session:
    counselor_a = make_user(session, "counselor.a@urios.edu.ph", UserRole.counselor, "Ana", "Reyes")
    counselor_b = make_user(session, "counselor.b@urios.edu.ph", UserRole.counselor, "Ben", "Cruz")
    inactive_counselor = make_user(
        session, "counselor.off@urios.edu.ph", UserRole.counselor, "Off", "Duty", active=False
    )
    other_student = make_user(session, "other@urios.edu.ph", UserRole.client, "Other", "Student")

    print("=== 2 consecutive rough days: yellow warning only, NO counselor alert ===")
    student_yellow = make_user(session, "yellow@urios.edu.ph", UserRole.client, "Yellow", "Student")
    add_past_mood(session, student_yellow, 1, 1)
    create_mood_entry(MoodEntryCreate(mood_level=2), student_yellow, session)
    student_notifs = session.exec(
        select(Notification).where(Notification.user_id == student_yellow.id)
    ).all()
    check(len(student_notifs) == 1 and "Gentle Check-in" in student_notifs[0].title,
          "student receives the gentle 2-day check-in")
    check(len(red_alerts_for(session, counselor_a)) == 0, "counselor A not alerted at 2 days")

    print("\n=== 3 consecutive rough days: Red Alert escalates to counselors ===")
    student_red = make_user(session, "red@urios.edu.ph", UserRole.client, "Rosa", "Dela Cruz")
    add_past_mood(session, student_red, 2, 1)
    add_past_mood(session, student_red, 1, 2)
    create_mood_entry(MoodEntryCreate(mood_level=1), student_red, session)

    student_notifs = session.exec(
        select(Notification).where(Notification.user_id == student_red.id)
    ).all()
    check(any("Caring Guidance Support" in n.title for n in student_notifs),
          "student still receives the caring guidance support notification")

    a_alerts = red_alerts_for(session, counselor_a)
    b_alerts = red_alerts_for(session, counselor_b)
    check(len(a_alerts) == 1, "counselor A receives exactly one Red Alert")
    check(len(b_alerts) == 1, "counselor B receives exactly one Red Alert")
    check(len(red_alerts_for(session, inactive_counselor)) == 0, "inactive counselor is not alerted")
    check(len(red_alerts_for(session, other_student)) == 0, "other students are never alerted")
    check(bool(a_alerts) and "Rosa Dela Cruz" in a_alerts[0].body and "3 consecutive days" in a_alerts[0].body,
          "alert body names the student and the 3-day streak")
    check(bool(a_alerts) and a_alerts[0].is_read is False, "alert is unread")

    print("\n=== Same-day repeat logging does not duplicate alerts ===")
    create_mood_entry(MoodEntryCreate(mood_level=1), student_red, session)
    check(len(red_alerts_for(session, counselor_a)) == 1, "still exactly one alert for counselor A")

    print("\n=== Instant alert does not suppress the daily counselor digest ===")
    _ensure_daily_notifications(session, counselor_a)
    session.commit()
    digest = session.exec(
        select(Notification).where(
            Notification.user_id == counselor_a.id, Notification.title != RED_ALERT_TITLE
        )
    ).all()
    check(any("Consistent Distress Alert" in n.title for n in digest),
          "daily digest still generated alongside the Red Alert")

    print("\n=== A non-rough day breaks the streak (no alert) ===")
    student_ok = make_user(session, "ok@urios.edu.ph", UserRole.client, "Okay", "Student")
    add_past_mood(session, student_ok, 2, 1)
    add_past_mood(session, student_ok, 1, 4)
    create_mood_entry(MoodEntryCreate(mood_level=1), student_ok, session)
    check(len(red_alerts_for(session, counselor_b)) == 1,
          "counselor B alert count unchanged (still only the earlier student)")

print()
if errors:
    print(f"RESULT: {len(errors)} check(s) FAILED")
    sys.exit(1)
print("RESULT: ALL CHECKS PASSED")
