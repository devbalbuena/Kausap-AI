import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def print_res(name, res):
    print(f"\n=== {name} ===")
    print(f"Status Code: {res.status_code}")
    try:
        print(json.dumps(res.json(), indent=2))
    except:
        print(res.text)

# 1. Successful Client Registration
client_payload = {
    "role": "client",
    "email": "client1@example.com",
    "password": "password123",
    "first_name": "Juan",
    "last_name": "Dela Cruz",
    "phone_number": "+639123456789",
    "birthday": "1990-01-01",
    "gender": "Male",
    "occupation": "Employed"
}
res = requests.post(f"{BASE_URL}/auth/register", json=client_payload)
print_res("TEST 1: Client Registration", res)

# 2. Successful Professional Registration
prof_payload = {
    "role": "professional",
    "email": "dr.smith@example.com",
    "password": "password123",
    "first_name": "Jane",
    "last_name": "Smith",
    "phone_number": "+639987654321",
    "birthday": "1985-05-15",
    "gender": "Female",
    "profession": "Psychologist",
    "prc_license_number": "RPsy-9999",
    "license_url": "https://s3.example.com/license.pdf",
    "specialization": "Clinical Psychology",
    "years_of_experience": 10,
    "location": "Makati City"
}
res = requests.post(f"{BASE_URL}/auth/register", json=prof_payload)
print_res("TEST 2: Professional Registration", res)

# 3. Reject Admin Registration
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
res = requests.post(f"{BASE_URL}/auth/register", json=admin_payload)
print_res("TEST 3: Admin Registration Rejection", res)
