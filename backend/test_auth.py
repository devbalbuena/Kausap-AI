import httpx
import json

BASE_URL = "http://127.0.0.1:8000"

def print_res(name, res):
    print(f"\n=== {name} ===")
    print(f"Status Code: {res.status_code}")
    try:
        print(json.dumps(res.json(), indent=2))
    except Exception:
        print(res.text)

# 1. Successful Client (Student) Registration
client_payload = {
    "role": "client",
    "email": "test_student_2026@example.com",
    "password": "password123",
    "first_name": "Maria",
    "last_name": "Santos",
    "phone_number": "+639123456789",
    "birthday": "2003-05-12",
    "gender": "Female",
    "occupation": "Student"
}
with httpx.Client() as client:
    res = client.post(f"{BASE_URL}/auth/register", json=client_payload)
    print_res("TEST 1: Client Registration", res)

    # 2. Reject Admin Registration
    admin_payload = {
        "role": "admin",
        "email": "hacker@example.com",
        "password": "password123",
        "first_name": "Evil",
        "last_name": "Hacker",
        "phone_number": "000000",
        "birthday": "2000-01-01",
        "gender": "Other"
    }
    res = client.post(f"{BASE_URL}/auth/register", json=admin_payload)
    print_res("TEST 2: Admin Registration Rejection", res)
