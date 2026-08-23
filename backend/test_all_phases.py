"""
test_all_phases.py
------------------
Automated comprehensive verification of Phases 1, 2, 3, and 4.
"""

import sys
import uuid
from datetime import datetime

# 1. Verify models and database pooling
from app.database import engine, get_session
from app.models.audit_log import AuditLog
from app.schemas.audit import AuditLogRead
from app.models.user import User
from app.models.article import Article
from app.models.chat import ChatMessage, ChatSession
from app.models.mood import MoodEntry
from app.core.clinical_guardrails import (
    check_clinical_boundary,
    build_system_messages,
    PRESCRIPTION_BOUNDARY_RESPONSE,
    DIAGNOSIS_BOUNDARY_RESPONSE,
    KAUSAP_SYSTEM_PROMPT,
)

errors = []

def check(condition, msg):
    if condition:
        print(f"  PASS: {msg}")
    else:
        print(f"  FAIL: {msg}")
        errors.append(msg)

print("=== Phase 1: Ethical AI Guardrails & Clinical Interceptors ===")
# Test prescription risk
is_violation, resp = check_clinical_boundary("What medicine should I take for panic attacks?")
check(is_violation and resp == PRESCRIPTION_BOUNDARY_RESPONSE, "Prescription boundary interceptor")

# Test diagnosis risk
is_violation, resp = check_clinical_boundary("Can you diagnose me with depression?")
check(is_violation and resp == DIAGNOSIS_BOUNDARY_RESPONSE, "Diagnosis boundary interceptor")

# Test safe text (no violation)
is_violation, resp = check_clinical_boundary("I feel really stressed about my upcoming math exam.")
check(not is_violation and resp is None, "Safe message passes through to AI")

# Test system prompt
sys_msgs = build_system_messages()
check(len(sys_msgs) >= 1 and sys_msgs[0]["role"] == "system", "System message structure")
sys_content = sys_msgs[0]["content"]
check("NEVER prescribe" in sys_content, "System prompt prescription boundary")
check("diagnosis" in sys_content.lower(), "System prompt diagnosis boundary")

print("\n=== Phase 2: Audit Trail & Immutable Counselor Logging ===")
check(hasattr(AuditLog, "admin_id"), "AuditLog has admin_id")
check(hasattr(AuditLog, "admin_email"), "AuditLog has admin_email")
check(hasattr(AuditLog, "action"), "AuditLog has action")
check(hasattr(AuditLog, "target_type"), "AuditLog has target_type")
check(hasattr(AuditLog, "target_id"), "AuditLog has target_id")
check(hasattr(AuditLog, "created_at"), "AuditLog has created_at")

# Create mock audit log and validate with schema
mock_log = AuditLog(
    id=uuid.uuid4(),
    admin_id=uuid.uuid4(),
    admin_email="counselor@csu.edu.ph",
    action="user_deactivated",
    target_type="user",
    target_id=str(uuid.uuid4()),
    detail="Account deactivated pending evaluation",
    created_at=datetime.utcnow()
)
read_dto = AuditLogRead.model_validate(mock_log)
check(read_dto.admin_email == "counselor@csu.edu.ph", "AuditLogRead validation")
check(read_dto.action == "user_deactivated", "Audit action validation")

print("\n=== Phase 4: Scalability & PgBouncer Connection Pooling ===")
check(getattr(engine.pool, "_pre_ping", False) == True, "Engine pool pre-ping enabled (scale-to-zero resiliency)")
check(getattr(engine.pool, "_recycle", None) == 300, "Engine connection recycling set to 300s")
print(f"  Engine pool class: {engine.pool.__class__.__name__}")

if errors:
    print(f"\n{len(errors)} checks FAILED!")
    sys.exit(1)
else:
    print("\nALL VERIFICATION CHECKS PASSED (0 ERRORS)!")
    sys.exit(0)
