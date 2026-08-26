import json
import urllib.request
import urllib.parse

BASE_URL = "http://127.0.0.1:8000"

def run_tests():
    print("=== Testing Emergency Hotlines API Endpoints ===")
    
    # 1. Login as Counselor
    login_data = json.dumps({
        "email": "counselor@urios.edu.ph",
        "password": "Counselor123!",
    }).encode("utf-8")
    
    req = urllib.request.Request(
        f"{BASE_URL}/auth/login",
        data=login_data,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req) as resp:
        token_data = json.loads(resp.read().decode())
        token = token_data["access_token"]
        print("  PASS: Authenticated Counselor -> token obtained")

    auth_headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    # 2. Public GET /crisis/hotlines
    req = urllib.request.Request(f"{BASE_URL}/crisis/hotlines")
    with urllib.request.urlopen(req) as resp:
        hotlines = json.loads(resp.read().decode())
        print(f"  PASS: GET /crisis/hotlines -> {len(hotlines)} hotlines found")
        assert len(hotlines) >= 6

    # 3. Counselor POST /admin/hotlines (Create)
    create_payload = json.dumps({
        "name": "FSUU Health Services & Clinic",
        "phone": "(085) 342-1830 loc. 210",
        "email": "clinic@urios.edu.ph",
        "description": "On-campus medical triage & first aid assistance",
        "category": "campus",
        "type": "call",
        "is_active": True,
        "sort_order": 1,
    }).encode("utf-8")

    req = urllib.request.Request(
        f"{BASE_URL}/admin/hotlines",
        data=create_payload,
        headers=auth_headers,
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        created = json.loads(resp.read().decode())
        hotline_id = created["id"]
        print(f"  PASS: POST /admin/hotlines -> Created '{created['name']}' (ID: {hotline_id})")

    # 4. Counselor PUT /admin/hotlines/{id} (Update)
    update_payload = json.dumps({
        "phone": "(085) 342-1830 loc. 215 / 0918-000-CLINIC",
        "description": "Updated 24/7 on-campus first aid and medical support",
    }).encode("utf-8")

    req = urllib.request.Request(
        f"{BASE_URL}/admin/hotlines/{hotline_id}",
        data=update_payload,
        headers=auth_headers,
        method="PUT",
    )
    with urllib.request.urlopen(req) as resp:
        updated = json.loads(resp.read().decode())
        assert "loc. 215" in updated["phone"]
        print(f"  PASS: PUT /admin/hotlines/{hotline_id} -> Updated phone: {updated['phone']}")

    # 5. Verify Public endpoint reflects the update
    req = urllib.request.Request(f"{BASE_URL}/crisis/hotlines")
    with urllib.request.urlopen(req) as resp:
        hotlines = json.loads(resp.read().decode())
        clinic = [h for h in hotlines if h["id"] == hotline_id]
        assert len(clinic) == 1
        print(f"  PASS: Public /crisis/hotlines immediately contains new campus hotline '{clinic[0]['name']}'")

    # 6. Counselor DELETE /admin/hotlines/{id}
    req = urllib.request.Request(
        f"{BASE_URL}/admin/hotlines/{hotline_id}",
        headers=auth_headers,
        method="DELETE",
    )
    with urllib.request.urlopen(req) as resp:
        delete_res = json.loads(resp.read().decode())
        print(f"  PASS: DELETE /admin/hotlines/{hotline_id} -> {delete_res['message']}")

    print("\nALL 6 HOTLINE ENDPOINT TESTS PASSED SUCCESSFULLY (0 ERRORS)!")

if __name__ == "__main__":
    run_tests()
