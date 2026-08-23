"""
audit_log.py
-------------
Immutable admin audit trail model for Kausap AI (NFR — Security & Audit Logging).

Every sensitive counselor/admin action is permanently written here with:
  - who performed it (admin_id, admin_email)
  - what was done (action)
  - what/who was affected (target_type, target_id)
  - when it happened (created_at — always UTC, never updated)
  - optional free-text justification (detail)

DESIGN DECISIONS:
  - No `updated_at` — audit records are IMMUTABLE once written.
  - `admin_email` is denormalized so the log is readable even if the admin
    account is later deleted.
  - `target_id` is str (not UUID) to accommodate both UUID user IDs and
    string article IDs without type coercion.
"""

from datetime import datetime
import uuid
from typing import Optional
from sqlmodel import Field, SQLModel


class AuditLog(SQLModel, table=True):
    __tablename__ = "auditlog"  # type: ignore[assignment]

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)

    # Who performed the action
    admin_id: uuid.UUID = Field(index=True)
    admin_email: str = Field(index=True)  # Denormalized — readable after account deletion

    # What was done — predefined action slugs for reliable filtering
    # Examples: user_deactivated, user_reactivated, user_archived, user_restored,
    #           appeal_approved, appeal_dismissed,
    #           article_published, article_updated, article_deleted
    action: str = Field(index=True)

    # What entity was affected
    target_type: str  # "user" | "article" | "message"
    target_id: str    # UUID or article ID as string

    # Optional counselor note / system-generated reason
    detail: Optional[str] = Field(default=None)

    # Immutable timestamp — UTC always
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)
