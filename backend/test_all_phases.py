"""
test_all_phases.py
------------------
Automated comprehensive verification of Phases 1-4, Guardrails, and RBAC Role Separation.
"""

import sys
import uuid
from datetime import datetime, timezone
from fastapi import HTTPException

# 1. Verify models, dependencies and database pooling
from app.database import engine, get_session
from app.models.audit_log import AuditLog
from app.schemas.audit import AuditLogRead
from app.models.user import User, UserRole
from app.schemas.user import UserCreate
from app.models.token_log import TokenUsageLog
from app.schemas.admin import (
    CounselorCreate, CounselorRead, CounselorStatusUpdate, CounselorPasswordReset,
    TokenTelemetrySummary, DailyTokenPoint, SystemHealthTelemetry,
)
from app.core.deps import get_current_admin, get_current_counselor, get_current_counselor_or_admin
from app.core.ai_provider import calculate_cost_usd
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

# Test system prompt & FSUU university branding
sys_msgs = build_system_messages()
check(len(sys_msgs) >= 1 and sys_msgs[0]["role"] == "system", "System message structure")
sys_content = sys_msgs[0]["content"]
check("NEVER prescribe" in sys_content, "System prompt prescription boundary")
check("diagnosis" in sys_content.lower(), "System prompt diagnosis boundary")
check("Father Saturnino Urios University" in sys_content or "FSUU" in sys_content, "FSUU University branding present in system prompt")

print("\n=== RBAC Role Separation Verification (Phase 1) ===")
check("counselor" in [r.value for r in UserRole], "UserRole contains 'counselor'")
check("admin" in [r.value for r in UserRole], "UserRole contains 'admin'")
check("client" in [r.value for r in UserRole], "UserRole contains 'client'")

# Mock users for testing role guards
mock_student = User(
    id=uuid.uuid4(),
    email="student@urios.edu.ph",
    hashed_password="pw",
    role=UserRole.client,
    first_name="Juan",
    last_name="Dela Cruz",
    phone_number="09123456789",
    birthday=datetime.now(timezone.utc).date(),
    gender="Male",
    is_active=True
)

mock_counselor = User(
    id=uuid.uuid4(),
    email="counselor@urios.edu.ph",
    hashed_password="pw",
    role=UserRole.counselor,
    first_name="Maria",
    last_name="Santos",
    phone_number="09123456789",
    birthday=datetime.now(timezone.utc).date(),
    gender="Female",
    department_title="Guidance Counselor III",
    is_active=True
)

mock_admin = User(
    id=uuid.uuid4(),
    email="admin@urios.edu.ph",
    hashed_password="pw",
    role=UserRole.admin,
    first_name="System",
    last_name="Admin",
    phone_number="09123456789",
    birthday=datetime.now(timezone.utc).date(),
    gender="Prefer not to say",
    is_active=True
)

# Test get_current_counselor_or_admin
check(get_current_counselor_or_admin(mock_counselor) == mock_counselor, "get_current_counselor_or_admin allows counselor")
check(get_current_counselor_or_admin(mock_admin) == mock_admin, "get_current_counselor_or_admin allows super admin")
try:
    get_current_counselor_or_admin(mock_student)
    check(False, "get_current_counselor_or_admin correctly rejects student (403)")
except HTTPException as e:
    check(e.status_code == 403, "get_current_counselor_or_admin rejects student with 403")

# Test get_current_admin (strictly super admin only)
check(get_current_admin(mock_admin) == mock_admin, "get_current_admin allows super admin")
try:
    get_current_admin(mock_counselor)
    check(False, "get_current_admin correctly rejects counselor (403)")
except HTTPException as e:
    check(e.status_code == 403, "get_current_admin rejects counselor with 403")

print("\n=== Phase 2: Counselor Provisioning & Token Telemetry (Phase 2) ===")
# Test CounselorCreate and CounselorRead DTO validation
c_payload = CounselorCreate(
    email="counselor.lead@urios.edu.ph",
    password="TemporaryPassword123!",
    first_name="Elena",
    last_name="Reyes",
    phone_number="09187654321",
    department_title="Head Guidance Counselor",
    gender="Female",
)
check(c_payload.email == "counselor.lead@urios.edu.ph", "CounselorCreate schema validation")

mock_counselor_read = CounselorRead(
    id=uuid.uuid4(),
    email=c_payload.email,
    full_name=f"{c_payload.first_name} {c_payload.last_name}",
    role="counselor",
    department_title=c_payload.department_title,
    phone_number=c_payload.phone_number,
    gender=c_payload.gender,
    is_active=True,
    created_at=datetime.now(timezone.utc),
)
check(mock_counselor_read.department_title == "Head Guidance Counselor", "CounselorRead schema validation")

# Test Token Cost calculation & TokenUsageLog
calculated_cost = calculate_cost_usd(1000, 500, "gpt-4o-mini")
# (1000 * 0.00000015) + (500 * 0.00000060) = 0.00015 + 0.00030 = 0.00045 USD
check(abs(calculated_cost - 0.00045) < 1e-6, f"calculate_cost_usd accurate: {calculated_cost} USD")

mock_token_log = TokenUsageLog(
    id=uuid.uuid4(),
    user_id=mock_student.id,
    session_id=uuid.uuid4(),
    model="gpt-4o-mini",
    prompt_tokens=1000,
    completion_tokens=500,
    total_tokens=1500,
    estimated_cost_usd=calculated_cost,
    created_at=datetime.now(timezone.utc),
)
check(mock_token_log.total_tokens == 1500, "TokenUsageLog model instantiation")
check(mock_token_log.estimated_cost_usd > 0, "TokenUsageLog estimated_cost_usd set")

# Test TokenTelemetrySummary DTO
summary = TokenTelemetrySummary(
    total_prompt_tokens=10000,
    total_completion_tokens=5000,
    total_tokens=15000,
    estimated_cost_usd=0.0045,
    estimated_cost_php=round(0.0045 * 57.50, 4),
    today_tokens=1500,
    today_cost_usd=0.00045,
    today_cost_php=round(0.00045 * 57.50, 4),
    daily_trends=[
        DailyTokenPoint(
            date="2026-08-25",
            prompt_tokens=1000,
            completion_tokens=500,
            total_tokens=1500,
            cost_usd=0.00045,
            cost_php=round(0.00045 * 57.50, 4),
        )
    ]
)
check(summary.total_tokens == 15000, "TokenTelemetrySummary validation")
check(summary.estimated_cost_php > 0, "PHP token cost conversion validation")

# Test SystemHealthTelemetry DTO
health_dto = SystemHealthTelemetry(
    status="Operational • Neon Serverless Active",
    database_connected=True,
    pool_size=20,
    pool_checked_out=2,
    pool_overflow=0,
    total_counselors=3,
    total_students=45,
    total_tokens_consumed=150000,
)
check(health_dto.database_connected == True, "SystemHealthTelemetry validation")

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
    admin_email="guidance@urios.edu.ph",
    action="counselor_created",
    target_type="user",
    target_id=str(uuid.uuid4()),
    detail="Provisioned verified counselor account: counselor.lead@urios.edu.ph",
    created_at=datetime.now(timezone.utc)
)
read_dto = AuditLogRead.model_validate(mock_log)
check(read_dto.admin_email == "guidance@urios.edu.ph", "AuditLogRead validation")
check(read_dto.action == "counselor_created", "Audit action validation")

print("\n=== Phase 4: Scalability & Connection Pooling ===")
check(getattr(engine.pool, "_pre_ping", False) == True, "Engine pool pre-ping enabled (scale-to-zero resiliency)")
check(getattr(engine.pool, "_recycle", None) == 300, "Engine connection recycling set to 300s")
print(f"  Engine pool class: {engine.pool.__class__.__name__}")

if errors:
    print(f"\n{len(errors)} checks FAILED!")
    sys.exit(1)
else:
    print("\nALL PHASE 2 VERIFICATION CHECKS PASSED (0 ERRORS)!")
    sys.exit(0)
