import urllib.request
import json

BASE_URL = "http://127.0.0.1:8000"

def test_multiple_journal_entries():
    print("=== Testing Multiple Daily Journals & Edit Workflow ===")

    # 1. Login
    login_data = json.dumps({"email": "client1@example.com", "password": "password123"}).encode("utf-8")
    req = urllib.request.Request(f"{BASE_URL}/auth/login", data=login_data, headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req) as resp:
        token = json.loads(resp.read().decode("utf-8"))["access_token"]
    print("  PASS: Authenticated Student (client1@example.com)")

    # 2. POST 1st Journal Entry of the day
    j1 = json.dumps({
        "title": "Morning Gratitude",
        "content": "Morning reflection: Woke up feeling energized and prepared for my morning exams.",
        "mood_tag": "Grateful",
        "prompt": "Best moment of my day:"
    }).encode("utf-8")
    req1 = urllib.request.Request(f"{BASE_URL}/journal", data=j1, headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"}, method="POST")
    with urllib.request.urlopen(req1) as resp:
        entry1 = json.loads(resp.read().decode("utf-8"))
        id1 = entry1["id"]
        print(f"  PASS: Created 1st Journal Entry ({id1})")

    # 3. POST 2nd Journal Entry of the same day (SHOULD NOT OVERWRITE)
    j2 = json.dumps({
        "title": "Afternoon Thoughts",
        "content": "Afternoon check-in: Took a 15-minute mindfulness walk around campus.",
        "mood_tag": "Calm",
        "prompt": "How I took care of myself today:"
    }).encode("utf-8")
    req2 = urllib.request.Request(f"{BASE_URL}/journal", data=j2, headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"}, method="POST")
    with urllib.request.urlopen(req2) as resp:
        entry2 = json.loads(resp.read().decode("utf-8"))
        id2 = entry2["id"]
        assert id1 != id2, "2nd entry must have a separate ID"
        print(f"  PASS: Created 2nd Separate Journal Entry ({id2})")

    # 4. PUT /journal/{id1} -> Edit 1st Journal Entry
    j_edit = json.dumps({
        "content": "Morning reflection (EDITED): Woke up feeling energized and aced my exam!",
        "mood_tag": "Motivated"
    }).encode("utf-8")
    req_put = urllib.request.Request(f"{BASE_URL}/journal/{id1}", data=j_edit, headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"}, method="PUT")
    with urllib.request.urlopen(req_put) as resp:
        updated1 = json.loads(resp.read().decode("utf-8"))
        assert "EDITED" in updated1["content"]
        assert updated1["mood_tag"] == "Motivated"
        print(f"  PASS: Successfully edited Journal Entry ({id1})")

    # 5. GET /journal/today -> Must return both entries
    req_today = urllib.request.Request(f"{BASE_URL}/journal/today", headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req_today) as resp:
        today_list = json.loads(resp.read().decode("utf-8"))
        assert len(today_list) >= 2
        print(f"  PASS: GET /journal/today returned {len(today_list)} entries for today")

    print("\nALL MULTIPLE JOURNALS & EDIT TESTS PASSED (0 ERRORS)!\n")

if __name__ == "__main__":
    test_multiple_journal_entries()
