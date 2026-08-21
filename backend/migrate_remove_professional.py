import os
from dotenv import load_dotenv
from sqlmodel import create_engine, text

load_dotenv("c:/Kausap-AI/backend/.env")
db_url = os.getenv("DATABASE_URL")
if not db_url:
    raise ValueError("DATABASE_URL not found in .env")

engine = create_engine(db_url)

with engine.begin() as conn:
    print("[*] Starting Database Clean-up for 2-Role System...")
    
    # 1. Delete rows from professionalprofile
    try:
        deleted_profiles = conn.execute(text("DELETE FROM professionalprofile")).rowcount
        print(f"[OK] Deleted {deleted_profiles} rows from professionalprofile table.")
    except Exception as e:
        print(f"[!] Notice during professionalprofile row deletion: {e}")

    # 2. Delete users with role 'professional'
    try:
        deleted_users = conn.execute(text("DELETE FROM \"user\" WHERE role = 'professional'")).rowcount
        print(f"[OK] Deleted {deleted_users} professional accounts from user table.")
    except Exception as e:
        print(f"[!] Notice during user deletion: {e}")

    # 3. Drop professionalprofile table
    try:
        conn.execute(text("DROP TABLE IF EXISTS professionalprofile CASCADE"))
        print("[OK] Dropped table professionalprofile.")
    except Exception as e:
        print(f"[!] Notice during table drop: {e}")

print("\n[SUCCESS] Database migration complete! Remaining users:")
with engine.connect() as conn:
    users = conn.execute(text('SELECT id, email, role, first_name, last_name FROM "user"')).fetchall()
    for u in users:
        print(f"  - {u[1]} ({u[2]}): {u[3]} {u[4]}")
