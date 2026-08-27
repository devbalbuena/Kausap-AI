import urllib.request
import urllib.parse
import json

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
    print("=== Testing Student Notification System & Unread Counter ===")
    
    token = login("balbuenadexter2@gmail.com", "Password@123")
    print("  PASS: Authenticated Student (balbuenadexter2@gmail.com)")

    # 1. Fetch notifications
    status, notifs = make_req("/notifications", token=token)
    assert status == 200, f"Expected 200, got {status}"
    assert len(notifs) >= 3, f"Expected at least 3 notifications, got {len(notifs)}"
    print(f"  PASS: GET /notifications -> {len(notifs)} notifications fetched successfully")

    # 2. Get unread count
    status, unread_res = make_req("/notifications/unread-count", token=token)
    assert status == 200, f"Expected 200, got {status}"
    unread_count = unread_res.get("count", 0)
    print(f"  PASS: GET /notifications/unread-count -> unread count is {unread_count}")

    # 3. Mark single notification as read if any unread
    unread_items = [n for n in notifs if not n.get("is_read")]
    if unread_items:
        target_id = unread_items[0]["id"]
        status, read_notif = make_req(f"/notifications/{target_id}/read", method="PUT", token=token)
        assert status == 200, f"Expected 200, got {status}"
        assert read_notif["is_read"] is True
        print(f"  PASS: PUT /notifications/{target_id}/read -> marked single notification as read")

    # 4. Mark all as read
    status, res = make_req("/notifications/read-all", method="PUT", token=token)
    assert status == 200, f"Expected 200, got {status}"
    print(f"  PASS: PUT /notifications/read-all -> {res.get('marked_read')} marked as read")

    # 5. Verify unread count is now 0
    status, final_unread = make_req("/notifications/unread-count", token=token)
    assert status == 200, f"Expected 200, got {status}"
    assert final_unread.get("count") == 0, f"Expected unread count 0, got {final_unread.get('count')}"
    print("  PASS: Verified unread count successfully reset to 0")

    print("\nALL NOTIFICATION TESTS PASSED SUCCESSFULLY (0 ERRORS)!")

if __name__ == "__main__":
    main()
