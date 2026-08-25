"""
migrate_roles.py
----------------
Database migration for Phase 1 Role Separation:
1. Adds department_title column to 'user' table if missing.
2. Updates any role constraints in PostgreSQL to allow 'counselor'.
"""

import sys
from sqlalchemy import text
from sqlmodel import Session, select
from app.database import engine
from app.models.user import User, UserRole

def run_migration():
    print("Starting Phase 1 Role Migration...")
    with Session(engine) as session:
        # 1. Add department_title column if missing
        try:
            session.exec(text('ALTER TABLE "user" ADD COLUMN IF NOT EXISTS department_title VARCHAR;'))
            session.commit()
            print("  [OK] Column 'department_title' verified/added.")
        except Exception as e:
            session.rollback()
            print(f"  [ERROR] Column addition: {e}")

        # 2. Check if postgres enum type exists and update if necessary
        try:
            session.exec(text("""
            DO $$
            BEGIN
                IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'userrole') THEN
                    ALTER TYPE userrole ADD VALUE IF NOT EXISTS 'counselor';
                END IF;
            END
            $$;
            """))
            session.commit()
            print("  [OK] Postgres enum 'userrole' verified/updated.")
        except Exception as e:
            session.rollback()
            print(f"  [ERROR] Enum update: {e}")

        # 3. Verify querying User table with UserRole enum
        users = session.exec(select(User).limit(5)).all()
        print(f"  [OK] User table query successful. Found {len(users)} sample records.")
        for u in users:
            print(f"    - User: {u.email} | Role: {u.role}")

    print("Phase 1 Role Migration complete!")

if __name__ == "__main__":
    run_migration()
