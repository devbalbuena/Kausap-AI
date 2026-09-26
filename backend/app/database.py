"""
database.py
-----------
Neon Serverless PostgreSQL Database Connection & Engine Configuration.
Enforces Scalability & High-Concurrency Connection Pooling (NFR — Scalability).

Phase 2 Hardening (Mass-Testing Ready — 45 concurrent students):
  - pool_size=5:  Base connections per Uvicorn worker. Keeps total open connections
                  well within Neon free-tier limit (~50 max). 5 × workers stays safe.
  - max_overflow=15: Burst headroom for peak moments (e.g., all 45 students send at once).
  - pool_timeout=10: Fail fast instead of hanging indefinitely if all connections busy.
  - pool_recycle=180: 3-minute recycle to retire stale sockets after Neon scale-to-zero.
  - pool_pre_ping=True: Liveness probe on every checkout — prevents "server closed connection"
    errors when Neon compute wakes from sleep.
  - DATABASE_POOL_URL: Optional env var to point to Neon's PgBouncer pooled endpoint
    (ep-xxx-pooler.neon.tech) for transaction-level pooling at the proxy layer, which
    multiplexes hundreds of app connections into far fewer Postgres server connections.
"""

import logging
from sqlmodel import SQLModel, create_engine, Session
from app.core.config import settings

logger = logging.getLogger("kausap.database")

# ── Connection URL resolution ─────────────────────────────────────────────────
# If DATABASE_POOL_URL is set, use it for all runtime queries (points to the
# Neon PgBouncer pooled endpoint). Fall back to DATABASE_URL otherwise.
_runtime_url = getattr(settings, "DATABASE_POOL_URL", "") or settings.DATABASE_URL

import app.models  # Required for SQLModel table registration

# ── Engine factory ────────────────────────────────────────────────────────────
connect_args: dict = {}
engine_kwargs: dict = {
    "echo": False,        # Suppress SQL logs in production
    "pool_pre_ping": True,  # Validate connection liveness before checkout (Neon scale-to-zero safe)
    "pool_recycle": 180,  # Recycle idle connections every 3 minutes
}

if "sqlite" in _runtime_url:
    connect_args["check_same_thread"] = False
else:
    # PostgreSQL / Neon PgBouncer optimised pool:
    # pool_size × uvicorn_workers should stay comfortably under Neon's connection limit.
    # Neon free tier: ~50 connections total. At 1 worker: 5+15=20 max. Safe headroom.
    engine_kwargs["pool_size"] = 5          # Base persistent connections per worker
    engine_kwargs["max_overflow"] = 15      # Extra burst connections (auto-closed on release)
    engine_kwargs["pool_timeout"] = 10      # Raise immediately if no connection within 10s
    # PgBouncer transaction mode does not support prepared statements
    if "pooler" in _runtime_url:
        connect_args["prepare_threshold"] = None  # Disable libpq prepared statements for pgbouncer

engine = create_engine(
    _runtime_url,
    connect_args=connect_args,
    **engine_kwargs,
)

logger.info(
    f"[Kausap DB] Engine created — pool_size=5, max_overflow=15, pool_timeout=10, "
    f"pool_recycle=180, pool_pre_ping=True | endpoint={'pooler' if 'pooler' in _runtime_url else 'direct'}"
)


def create_db_and_tables():
    """Create all registered tables if they do not already exist, and safely apply incremental DDL.

    NOTE: DDL migrations always use the raw DATABASE_URL (direct endpoint), never the pooler,
    because PgBouncer transaction mode does not allow DDL statements in pooled sessions.
    """
    from sqlalchemy import text

    # Use direct URL for DDL — pooler can't run DDL in transaction mode
    _ddl_engine = engine
    if "pooler" in _runtime_url and settings.DATABASE_URL != _runtime_url:
        _ddl_engine_url = settings.DATABASE_URL
        _ddl_connect_args = {}
        _ddl_engine = create_engine(
            _ddl_engine_url,
            connect_args=_ddl_connect_args,
            pool_pre_ping=True,
            pool_size=2,
            max_overflow=0,
        )

    SQLModel.metadata.create_all(_ddl_engine)

    # Safe incremental schema upgrades for Neon Postgres
    if "sqlite" not in settings.DATABASE_URL:
        raw_conn = _ddl_engine.raw_connection()
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

        with _ddl_engine.begin() as conn:
            try:
                conn.execute(text("ALTER TABLE notification ADD COLUMN IF NOT EXISTS is_acknowledged BOOLEAN DEFAULT FALSE;"))
                conn.execute(text("ALTER TABLE notification ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMP WITHOUT TIME ZONE;"))
                conn.execute(text("ALTER TABLE notification ADD COLUMN IF NOT EXISTS call_slip_json TEXT;"))
                conn.execute(text('ALTER TABLE "user" ADD COLUMN IF NOT EXISTS department_title VARCHAR;'))
            except Exception:
                pass


def get_session():
    """FastAPI dependency for thread-safe database sessions."""
    with Session(engine) as session:
        yield session
