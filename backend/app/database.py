"""
database.py
-----------
Neon Serverless PostgreSQL Database Connection & Engine Configuration.
Enforces Scalability & High-Concurrency Connection Pooling (NFR — Scalability).

Key optimizations for Neon Serverless & Scale-to-Zero architecture:
  - pool_pre_ping=True: Validates liveness before checkout to prevent stale
    connection errors when Neon compute wakes from scale-to-zero.
  - pool_recycle=300: Recycles connections every 5 minutes to prevent holding
    stale sockets across compute sleep cycles.
  - pool_size=20 & max_overflow=10: Handles concurrent student peak loads
    (e.g., morning campus check-ins).
"""

from sqlmodel import SQLModel, create_engine, Session
from app.core.config import settings
import app.models  # Required for SQLModel table registration

# Configure engine with connection pooling & scale-to-zero resiliency
connect_args = {}
engine_kwargs = {
    "echo": False,  # Cleaner logs in production
    "pool_pre_ping": True,  # Liveness probe on checkout for Neon scale-to-zero
    "pool_recycle": 300,    # Recycle idle connections every 5 minutes
}

if "sqlite" in settings.DATABASE_URL:
    connect_args["check_same_thread"] = False
else:
    # PostgreSQL / Neon pooling settings
    engine_kwargs["pool_size"] = 20
    engine_kwargs["max_overflow"] = 10

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    **engine_kwargs
)


def create_db_and_tables():
    """Create all registered tables if they do not already exist, and safely apply incremental DDL."""
    from sqlalchemy import text
    SQLModel.metadata.create_all(engine)

    # Safe incremental schema upgrades for Neon Postgres
    if "sqlite" not in settings.DATABASE_URL:
        raw_conn = engine.raw_connection()
        try:
            raw_conn.set_isolation_level(0)  # AUTOCOMMIT
            with raw_conn.cursor() as cursor:
                try:
                    cursor.execute("ALTER TYPE notificationtype ADD VALUE IF NOT EXISTS 'guidance_notice';")
                except Exception:
                    pass
        except Exception:
            pass
        finally:
            raw_conn.close()

        with engine.begin() as conn:
            try:
                conn.execute(text("ALTER TABLE notification ADD COLUMN IF NOT EXISTS is_acknowledged BOOLEAN DEFAULT FALSE;"))
                conn.execute(text("ALTER TABLE notification ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMP WITHOUT TIME ZONE;"))
                conn.execute(text("ALTER TABLE notification ADD COLUMN IF NOT EXISTS call_slip_json TEXT;"))
            except Exception:
                pass



def get_session():
    """FastAPI dependency for thread-safe database sessions."""
    with Session(engine) as session:
        yield session
