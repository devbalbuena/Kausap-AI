"""
Automated backend verification suite for:
  1. Pydantic input sanitization & bounds (Chat, Journal, Mood, Hotline schemas)
  2. Firebase Hosting & local development CORS origin regex matching
  3. FastAPI HTTP security response headers on /health
"""
import re
from pydantic import ValidationError
from fastapi.testclient import TestClient

from app.main import app, CORS_ORIGIN_REGEX
from app.schemas.chat import ChatMessageCreate
from app.schemas.journal import JournalCreate, JournalUpdate
from app.schemas.mood import MoodEntryCreate
from app.schemas.hotline import HotlineCreate


def test_chat_and_journal_sanitization() -> None:
    msg = ChatMessageCreate(content="  Kumusta\x00 po!  ")
    assert msg.content == "Kumusta po!"

    try:
        ChatMessageCreate(content="   \x00   ")
        raise AssertionError("Expected ValidationError for whitespace-only chat content")
    except ValidationError:
        pass

    journal = JournalCreate(content="  Today I felt grateful.\x07 ")
    assert journal.content == "Today I felt grateful."

    upd = JournalUpdate(content="  Updated entry\x00  ")
    assert upd.content == "Updated entry"


def test_mood_and_hotline_validation() -> None:
    mood = MoodEntryCreate(mood_level=4, intensity=7, note="  Calm study session\x00 ")
    assert mood.note == "Calm study session"

    try:
        MoodEntryCreate(mood_level=9)
        raise AssertionError("Expected ValidationError for mood_level > 5")
    except ValidationError:
        pass

    hotline = HotlineCreate(
        name="  FSUU Guidance  ",
        phone="  (085) 342-1830  ",
        category="CAMPUS",
        type="CALL",
    )
    assert hotline.name == "FSUU Guidance"
    assert hotline.phone == "(085) 342-1830"
    assert hotline.category == "campus"
    assert hotline.type == "call"

    try:
        HotlineCreate(name="Test", phone="123", category="invalid_cat")
        raise AssertionError("Expected ValidationError for invalid hotline category")
    except ValidationError:
        pass


def test_cors_origin_regex() -> None:
    allowed = [
        "https://kausap-ai.web.app",
        "https://kausap-ai.firebaseapp.com",
        "https://kausap-ai.onrender.com",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
    ]
    for origin in allowed:
        assert re.fullmatch(CORS_ORIGIN_REGEX, origin), f"Expected origin to match: {origin}"

    blocked = [
        "https://malicious-site.example.com",
        "http://kausap-ai.web.app",  # non-HTTPS on production domain
    ]
    for origin in blocked:
        assert not re.fullmatch(CORS_ORIGIN_REGEX, origin), f"Expected origin to be rejected: {origin}"


def test_security_headers_on_health_endpoint() -> None:
    client = TestClient(app)
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}
    assert res.headers.get("X-Content-Type-Options") == "nosniff"
    assert res.headers.get("X-Frame-Options") == "DENY"
    assert res.headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    assert "geolocation=()" in (res.headers.get("Permissions-Policy") or "")


if __name__ == "__main__":
    test_chat_and_journal_sanitization()
    test_mood_and_hotline_validation()
    test_cors_origin_regex()
    test_security_headers_on_health_endpoint()
    print("ALL SECURITY, VALIDATION & CORS TESTS PASSED!")
