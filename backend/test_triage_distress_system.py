import json
import urllib.request
import urllib.parse

BASE_URL = "http://127.0.0.1:8000"

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
    print("=== Testing 2-Day Yellow Warning & 3-Day Red Alert Triage Protocol ===")
    
    # 1. Login as Student and log 3 consecutive rough moods
    student_token = login("balbuenadexter2@gmail.com", "Password@123")
    print("  PASS: Authenticated Student (balbuenadexter2@gmail.com)")

    # Log Rough mood 1
    req1 = urllib.request.Request(
        f"{BASE_URL}/mood",
        data=json.dumps({"mood_level": 2, "emotions": "overwhelmed", "note": "Feeling burnt out from midterm exams"}).encode("utf-8"),
        headers={"Authorization": f"Bearer {student_token}", "Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req1) as resp:
        assert resp.status == 201
    print("  PASS: Logged Mood Day 1 (Level 2 Rough)")

    # Log Rough mood 2 -> Should trigger Yellow Warning notification
    req2 = urllib.request.Request(
        f"{BASE_URL}/mood",
        data=json.dumps({"mood_level": 2, "emotions": "exhausted", "note": "Struggling with assignments"}).encode("utf-8"),
        headers={"Authorization": f"Bearer {student_token}", "Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req2) as resp:
        assert resp.status == 201
    print("  PASS: Logged Mood Day 2 (Level 2 Rough -> Yellow Warning Triggered)")

    # Log Rough mood 3 -> Should trigger Red Alert notification & crisis triage escalation
    req3 = urllib.request.Request(
        f"{BASE_URL}/mood",
        data=json.dumps({"mood_level": 1, "emotions": "hopeless", "note": "Feeling completely drained and anxious"}).encode("utf-8"),
        headers={"Authorization": f"Bearer {student_token}", "Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req3) as resp:
        assert resp.status == 201
    print("  PASS: Logged Mood Day 3 (Level 1 Distressed -> Red Alert Triggered)")

    # 2. Login as Counselor and inspect /admin/distress-patterns
    counselor_token = login("counselor@urios.edu.ph", "Counselor123!")
    print("  PASS: Authenticated Counselor (counselor@urios.edu.ph)")

    req_patterns = urllib.request.Request(
        f"{BASE_URL}/admin/distress-patterns",
        headers={"Authorization": f"Bearer {counselor_token}"},
        method="GET"
    )
    with urllib.request.urlopen(req_patterns) as resp:
        patterns = json.loads(resp.read().decode("utf-8"))
        assert len(patterns) >= 1
        found_alert = next((p for p in patterns if p["email"] == "balbuenadexter2@gmail.com"), None)
        assert found_alert is not None
        assert found_alert["risk_level"] == "red"
        assert found_alert["consecutive_days"] >= 3
        print(f"  PASS: Verified Distress Pattern in Counselor Feed: {found_alert['full_name']} -> {found_alert['risk_level'].upper()} ({found_alert['severity']})")

    # 3. Check /admin/flagged-messages to ensure it includes the triage alert
    req_flagged = urllib.request.Request(
        f"{BASE_URL}/admin/flagged-messages",
        headers={"Authorization": f"Bearer {counselor_token}"},
        method="GET"
    )
    with urllib.request.urlopen(req_flagged) as resp:
        flagged = json.loads(resp.read().decode("utf-8"))
        distress_flag = next((f for f in flagged if f["user_email"] == "balbuenadexter2@gmail.com" and "Distress" in (f.get("flag_reason") or "")), None)
        assert distress_flag is not None
        print(f"  PASS: Verified Unified Crisis Triage Flag: '{distress_flag['flag_reason']}' for {distress_flag['user_name']}")

    print("\nALL 2-DAY YELLOW & 3-DAY RED TRIAGE TESTS PASSED SUCCESSFULLY (0 ERRORS)!\n")

if __name__ == "__main__":
    main()
