"""
audit.py — Pydantic schemas for the Admin Audit Trail API.
"""

from datetime import datetime
import uuid
from typing import Optional
from pydantic import BaseModel


class AuditLogRead(BaseModel):
    id: uuid.UUID
    admin_id: uuid.UUID
    admin_email: str
    action: str
    target_type: str
    target_id: str
    detail: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}
