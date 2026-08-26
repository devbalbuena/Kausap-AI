import urllib.request
import urllib.parse
import json
import uuid

BASE_URL = "http://127.0.0.1:8000"

def make_req(path, method="GET", body=None, token=None):
    url = f"{BASE_URL}{path}"
    data = json.dumps(body).encode("utf-8") if body is not None else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode("utf-8")) if e.fp else str(e)

def login(email, password):
    data = json.dumps({"email": email, "password": password}).encode("utf-8")
    req = urllib.request.Request(
        f"{BASE_URL}/auth/login",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))["access_token"]

def main():
    print("=== Testing Bidirectional Counselor & Admin Crisis Triage Sync ===")
    
    # 1. Login Counselor & Admin
    counselor_token = login("counselor@urios.edu.ph", "Counselor123!")
    admin_token = login("admin@kausap.ai", "Admin123!")
    print("  PASS: Counselor & Admin authenticated")

    # 2. Student triggers flagged SOS message in DB
    from sqlmodel import Session, select
    from app.database import engine
    from app.models.chat import ChatMessage, ChatSession
    from app.models.user import User

    with Session(engine) as session:
        student = session.exec(select(User).where(User.role == "client")).first()
        if not student:
            print("  ERROR: No student found")
            return
        
        # Create a test session and flagged message
        chat_sess = ChatSession(user_id=student.id, title="Distress Test Session")
        session.add(chat_sess)
        session.commit()
        session.refresh(chat_sess)

        msg = ChatMessage(
            session_id=chat_sess.id,
            role="user",
            content="🚨 EMERGENCY SOS DISTRESS ALERT: Student triggered 1-tap campus crisis dispatch.",
            risk_flag=True,
        )
        session.add(msg)
        session.commit()
        session.refresh(msg)
        test_msg_id = str(msg.id)
        test_sess_id = chat_sess.id
        print(f"  PASS: Created active distress message in DB (ID: {test_msg_id})")

    # 3. Counselor queries /admin/flagged-messages -> verifies message is in active list
    status, counselor_flags = make_req("/admin/flagged-messages", token=counselor_token)
    assert status == 200, f"Expected 200, got {status}"
    active_for_counselor = [f for f in counselor_flags if str(f["id"]) == test_msg_id and not f["is_resolved"]]
    assert len(active_for_counselor) == 1, "Counselor should see active distress flag"
    print("  PASS: Counselor sees active distress alert in Active queue")

    # 4. Admin queries /admin/flagged-messages -> verifies message is also in active list
    status, admin_flags = make_req("/admin/flagged-messages", token=admin_token)
    assert status == 200, f"Expected 200, got {status}"
    active_for_admin = [f for f in admin_flags if str(f["id"]) == test_msg_id and not f["is_resolved"]]
    assert len(active_for_admin) == 1, "Admin should see active distress flag"
    print("  PASS: Admin sees active distress alert in Active queue")

    # 5. Counselor resolves the alert with clinical intake note
    status, res = make_req(
        f"/admin/flagged-messages/{test_msg_id}/resolve",
        method="PATCH",
        body={"resolution_note": "Conducted intake consultation with student at Guidance Office."},
        token=counselor_token
    )
    assert status == 200, f"Expected 200, got {status}: {res}"
    print("  PASS: Counselor resolved the distress alert with clinical note")

    # 6. Admin queries /admin/flagged-messages -> verifies it is NO LONGER active and is now RESOLVED
    status, admin_flags_after = make_req("/admin/flagged-messages", token=admin_token)
    assert status == 200, f"Expected 200, got {status}"
    active_after = [f for f in admin_flags_after if str(f["id"]) == test_msg_id and not f["is_resolved"]]
    resolved_after = [f for f in admin_flags_after if str(f["id"]) == test_msg_id and f["is_resolved"]]
    
    assert len(active_after) == 0, "Alert should no longer be in Active queue for Admin"
    assert len(resolved_after) == 1, "Alert should now be in Resolved Log for Admin"
    assert "Conducted intake consultation" in resolved_after[0]["resolution_note"], "Clinical note should be present"
    print(f"  PASS: Admin immediately sees alert in Resolved Log: note='{resolved_after[0]['resolution_note']}'")

    # Cleanup test message
    with Session(engine) as session:
        m = session.get(ChatMessage, uuid.UUID(test_msg_id))
        if m:
            session.delete(m)
        cs = session.get(ChatSession, test_sess_id)
        if cs:
            session.delete(cs)
        session.commit()
    print("  PASS: Test cleanup complete")

    print("\nALL BIDIRECTIONAL SYNC CHECKS PASSED SUCCESSFULLY (0 ERRORS)!")

if __name__ == "__main__":
    main()
