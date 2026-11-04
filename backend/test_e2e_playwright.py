"""
Kausap AI - Automated End-to-End Test Suite (6 core scenarios)
==============================================================

Runs the six core scenarios documented in the manuscript against a RUNNING Kausap AI
backend and prints a PASS/FAIL report with measured latency for each one:

  1. AI Conversation          - student message gets a non-empty empathetic reply
  2. Clinical Guardrail       - medication request is intercepted (no AI call, no prescription)
  3. PHQ-9 Screener           - severe total score (>= 15) is flagged for counselor review
  4. Question 9 Fatal Rule    - PHQ-9 item 9 > 0 is flagged even when the total score is low
  5. Daily Mood Log           - mood entry can be saved and read back
  6. 3-Day Distress Triage    - 3 consecutive low moods appear as a RED alert in the counselor queue

Usage
-----
    python test_e2e_playwright.py --url http://localhost:8000
    python test_e2e_playwright.py --url http://localhost:8000 \
        --counselor-email counselor@urios.edu.ph --counselor-password "secret"

Scenario 6 needs a counselor login (flags are only visible to counselors). Credentials can also
be supplied through the KAUSAP_COUNSELOR_EMAIL / KAUSAP_COUNSELOR_PASSWORD environment variables.
Without them scenario 6 is reported as SKIPPED (not failed).

By default a throw-away student account (e2e.<random>@urios.edu.ph) is registered. Run this
against a local or staging backend rather than production data. Use --student-email /
--student-password to reuse an existing student account instead.

The original Flutter-web browser smoke test (Playwright) is still available with --browser.
Exit code: 0 when no scenario FAILED, 1 otherwise.
"""
import argparse
import os
import sys
import time
import uuid

import httpx

# Latency targets (milliseconds) that apply to deterministic, non-LLM steps.
# The AI conversation depends on an external LLM provider, so its latency is reported only.
LATENCY_TARGET_MS = 800
GUARDRAIL_LOCAL_TARGET_MS = 2.0

PASS, FAIL, SKIP = "PASS", "FAIL", "SKIPPED"


class Result:
    def __init__(self, name: str):
        self.name = name
        self.status = FAIL
        self.latency_ms = None
        self.detail = ""

    def ok(self, latency_ms=None, detail=""):
        self.status, self.latency_ms, self.detail = PASS, latency_ms, detail
        return self

    def fail(self, detail, latency_ms=None):
        self.status, self.latency_ms, self.detail = FAIL, latency_ms, detail
        return self

    def skip(self, detail):
        self.status, self.detail = SKIP, detail
        return self


class Api:
    def __init__(self, base_url: str, timeout: float = 60.0):
        self.client = httpx.Client(base_url=base_url.rstrip("/"), timeout=timeout)
        self.token = None

    def _headers(self):
        return {"Authorization": f"Bearer {self.token}"} if self.token else {}

    def request(self, method, path, **kwargs):
        start = time.perf_counter()
        res = self.client.request(method, path, headers=self._headers(), **kwargs)
        return res, (time.perf_counter() - start) * 1000.0

    def login(self, email, password):
        res, _ = self.request("POST", "/auth/login", json={"email": email, "password": password})
        res.raise_for_status()
        self.token = res.json()["access_token"]

    def register(self, email, password):
        payload = {
            "email": email,
            "password": password,
            "first_name": "E2E",
            "last_name": "Tester",
            "phone_number": "09123456789",
            "birthday": "2000-01-01",
            "gender": "Prefer not to say",
            "occupation": "Student",
        }
        res, _ = self.request("POST", "/auth/register", json=payload)
        res.raise_for_status()
        self.token = res.json()["access_token"]


# ── Scenarios ────────────────────────────────────────────────────────────────

def scenario_ai_conversation(api: Api, ctx: dict) -> Result:
    r = Result("AI Conversation")
    res, _ = api.request("POST", "/chat/sessions")
    if res.status_code != 201:
        return r.fail(f"could not create chat session (HTTP {res.status_code})")
    ctx["session_id"] = res.json()["id"]

    res, ms = api.request(
        "POST",
        f"/chat/sessions/{ctx['session_id']}/messages",
        json={"content": "I feel really stressed about my thesis defense next week.", "persona": "buddy"},
    )
    if res.status_code != 200:
        return r.fail(f"HTTP {res.status_code}: {res.text[:120]}", ms)
    body = res.json()
    if body.get("role") != "assistant" or not body.get("content", "").strip():
        return r.fail("assistant reply was empty", ms)
    if body.get("risk_flag"):
        return r.fail("ordinary stress message was wrongly risk-flagged", ms)
    return r.ok(ms, f"{len(body['content'])} chars reply")


def scenario_clinical_guardrail(api: Api, ctx: dict) -> Result:
    r = Result("Clinical Guardrail")
    session_id = ctx.get("session_id")
    if not session_id:
        res, _ = api.request("POST", "/chat/sessions")
        if res.status_code != 201:
            return r.fail(f"could not create chat session (HTTP {res.status_code})")
        session_id = ctx["session_id"] = res.json()["id"]

    res, ms = api.request(
        "POST",
        f"/chat/sessions/{session_id}/messages",
        json={"content": "What medicine should I take for my panic attacks? Give me the dosage.", "persona": "buddy"},
    )
    if res.status_code != 200:
        return r.fail(f"HTTP {res.status_code}: {res.text[:120]}", ms)
    reply = res.json().get("content", "")
    if "not medically qualified" not in reply or "Guidance" not in reply:
        return r.fail("medication request was NOT intercepted by the clinical guardrail", ms)

    detail = "medication request intercepted, referral to FSUU Guidance given"
    local_ms = _local_guardrail_ms()
    if local_ms is not None:
        if local_ms >= GUARDRAIL_LOCAL_TARGET_MS:
            return r.fail(f"regex interceptor took {local_ms:.3f} ms (target < {GUARDRAIL_LOCAL_TARGET_MS} ms)", ms)
        detail += f"; regex interceptor {local_ms:.3f} ms"
    return r.ok(ms, detail)


def _local_guardrail_ms():
    """Time the regex interceptor in-process (only possible when run from the backend folder)."""
    try:
        from app.core.clinical_guardrails import check_clinical_boundary
    except Exception:
        return None
    text = "What medicine should I take for my panic attacks? Give me the dosage."
    check_clinical_boundary(text)  # warm-up
    runs = 200
    start = time.perf_counter()
    for _ in range(runs):
        check_clinical_boundary(text)
    return (time.perf_counter() - start) * 1000.0 / runs


def scenario_phq9(api: Api, ctx: dict) -> Result:
    r = Result("PHQ-9 Screener")
    severe = {"screener": "phq9", "score": 18, "severity": "Moderately severe", "answers": [2, 2, 2, 2, 2, 2, 2, 2, 0]}
    res, ms = api.request("POST", "/screeners/flag", json=severe)
    if res.status_code != 200:
        return r.fail(f"HTTP {res.status_code}: {res.text[:120]}", ms)
    data = res.json()
    if not data.get("flagged") or not any("total score" in x for x in data.get("reasons", [])):
        return r.fail("PHQ-9 total score 18 (>= 15) was not flagged for the counselor", ms)

    mild = {"screener": "phq9", "score": 6, "severity": "Mild", "answers": [1, 1, 1, 1, 1, 1, 0, 0, 0]}
    res, _ = api.request("POST", "/screeners/flag", json=mild)
    if res.status_code != 200 or res.json().get("flagged"):
        return r.fail("mild PHQ-9 score 6 was wrongly flagged")
    if ms >= LATENCY_TARGET_MS:
        return r.fail(f"response took {ms:.0f} ms (target < {LATENCY_TARGET_MS} ms)", ms)
    return r.ok(ms, "score 18 flagged, score 6 not flagged")


def scenario_question9(api: Api, ctx: dict) -> Result:
    r = Result("Question 9 Fatal Rule")
    # Total score is only 3 (Minimal) but item 9 (self-harm thoughts) is answered above 0.
    payload = {"screener": "phq9", "score": 3, "severity": "Minimal", "answers": [0, 0, 0, 0, 0, 0, 0, 2, 1]}
    res, ms = api.request("POST", "/screeners/flag", json=payload)
    if res.status_code != 200:
        return r.fail(f"HTTP {res.status_code}: {res.text[:120]}", ms)
    data = res.json()
    if not data.get("flagged") or not any("item 9" in x for x in data.get("reasons", [])):
        return r.fail("item 9 > 0 did not trigger the fatal override despite a low total score", ms)
    if ms >= LATENCY_TARGET_MS:
        return r.fail(f"response took {ms:.0f} ms (target < {LATENCY_TARGET_MS} ms)", ms)
    return r.ok(ms, "item 9 override flagged a Minimal-total result")


def scenario_mood_log(api: Api, ctx: dict) -> Result:
    r = Result("Daily Mood Log")
    res, ms = api.request("POST", "/mood", json={"mood_level": 3, "emotions": ["Calm"], "note": "e2e mood log"})
    if res.status_code != 201:
        return r.fail(f"HTTP {res.status_code}: {res.text[:120]}", ms)
    entry_id = res.json()["id"]
    res, _ = api.request("GET", "/mood")
    if res.status_code != 200 or entry_id not in [e["id"] for e in res.json()]:
        return r.fail("saved mood entry was not returned by GET /mood", ms)
    if ms >= LATENCY_TARGET_MS:
        return r.fail(f"response took {ms:.0f} ms (target < {LATENCY_TARGET_MS} ms)", ms)
    return r.ok(ms, "mood entry saved and read back")


def scenario_distress_triage(api: Api, ctx: dict) -> Result:
    r = Result("3-Day Distress Triage")
    email = ctx.get("counselor_email")
    password = ctx.get("counselor_password")
    if not email or not password:
        return r.skip("no counselor credentials (use --counselor-email/--counselor-password)")

    # Student logs three consecutive low check-ins.
    for level in (1, 2, 1):
        res, _ = api.request("POST", "/mood", json={"mood_level": level, "note": "e2e distress check"})
        if res.status_code != 201:
            return r.fail(f"could not log low mood (HTTP {res.status_code})")

    # Counselor opens the distress dashboard.
    counselor = Api(str(api.client.base_url))
    try:
        counselor.login(email, password)
    except Exception as exc:  # noqa: BLE001
        return r.fail(f"counselor login failed: {exc}")
    res, ms = counselor.request("GET", "/admin/distress-patterns")
    if res.status_code != 200:
        return r.fail(f"HTTP {res.status_code}: {res.text[:120]}", ms)
    mine = [a for a in res.json() if a["email"] == ctx["student_email"]]
    if not mine or mine[0]["risk_level"] != "red":
        return r.fail("student with 3 consecutive low moods is not a RED alert in the counselor queue", ms)
    if ms >= LATENCY_TARGET_MS:
        return r.fail(f"response took {ms:.0f} ms (target < {LATENCY_TARGET_MS} ms)", ms)
    return r.ok(ms, f"RED alert raised ({mine[0]['consecutive_days']} consecutive low check-ins)")


SCENARIOS = [
    scenario_ai_conversation,
    scenario_clinical_guardrail,
    scenario_phq9,
    scenario_question9,
    scenario_mood_log,
    scenario_distress_triage,
]


# ── Optional Flutter-web browser smoke test (original behaviour) ─────────────

def run_browser_smoke(target_url: str) -> bool:
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("  Playwright is not installed (pip install playwright && playwright install chromium).")
        return False
    print(f"\n=== Browser smoke test on {target_url} ===")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_context(viewport={"width": 420, "height": 840}).new_page()
        try:
            page.goto(target_url, timeout=15000)
            page.wait_for_load_state("domcontentloaded")
            page.wait_for_timeout(2000)
            print(f"  Page title: '{page.title()}'")
            page.screenshot(path="e2e_screen_preview.png")
            print("  Saved screenshot to e2e_screen_preview.png")
        except Exception as exc:  # noqa: BLE001
            print(f"  Could not reach {target_url} ({exc}). Ensure Flutter is running (`flutter run -d chrome`).")
            browser.close()
            return False
        browser.close()
    return True


# ── Runner ───────────────────────────────────────────────────────────────────

def run_suite(args) -> int:
    print(f"=== Kausap AI E2E Test Suite - {args.url} ===")
    api = Api(args.url)

    try:
        res, _ = api.request("GET", "/health")
        res.raise_for_status()
    except Exception as exc:  # noqa: BLE001
        print(f"\nCannot reach backend at {args.url} ({exc}).")
        print("Start it first:  uvicorn app.main:app --port 8000")
        return 1

    ctx = {
        "counselor_email": args.counselor_email or os.getenv("KAUSAP_COUNSELOR_EMAIL"),
        "counselor_password": args.counselor_password or os.getenv("KAUSAP_COUNSELOR_PASSWORD"),
    }
    try:
        if args.student_email:
            api.login(args.student_email, args.student_password or "")
            ctx["student_email"] = args.student_email
        else:
            ctx["student_email"] = f"e2e.{uuid.uuid4().hex[:10]}@urios.edu.ph"
            api.register(ctx["student_email"], "E2eTest#2026")
        print(f"Student account: {ctx['student_email']}\n")
    except Exception as exc:  # noqa: BLE001
        print(f"Could not sign in / register the test student: {exc}")
        return 1

    results = []
    for scenario in SCENARIOS:
        try:
            results.append(scenario(api, ctx))
        except Exception as exc:  # noqa: BLE001
            results.append(Result(scenario.__name__.replace("scenario_", "")).fail(f"unexpected error: {exc}"))

    print(f"{'#':<3}{'Scenario':<26}{'Latency':>11}  {'Status':<8}Detail")
    print("-" * 100)
    for i, res in enumerate(results, 1):
        latency = f"{res.latency_ms:.1f} ms" if res.latency_ms is not None else "-"
        print(f"{i:<3}{res.name:<26}{latency:>11}  {res.status:<8}{res.detail}")
    print("-" * 100)

    failed = [x for x in results if x.status == FAIL]
    skipped = [x for x in results if x.status == SKIP]
    passed = [x for x in results if x.status == PASS]
    print(f"Passed: {len(passed)}   Failed: {len(failed)}   Skipped: {len(skipped)}   Total: {len(results)}")
    if failed:
        print("\nE2E SUITE FAILED")
        return 1
    print("\nE2E SUITE COMPLETED SUCCESSFULLY" + (" (some scenarios skipped)" if skipped else "!"))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Kausap AI end-to-end test suite")
    parser.add_argument("--url", default="http://localhost:8000", help="Backend base URL")
    parser.add_argument("--student-email", help="Reuse an existing student instead of registering a new one")
    parser.add_argument("--student-password", help="Password for --student-email")
    parser.add_argument("--counselor-email", help="Counselor login for scenario 6")
    parser.add_argument("--counselor-password", help="Counselor password for scenario 6")
    parser.add_argument("--browser", metavar="FLUTTER_URL", help="Also run the Playwright browser smoke test")
    args = parser.parse_args()

    code = run_suite(args)
    if args.browser and not run_browser_smoke(args.browser):
        code = code or 1
    return code


if __name__ == "__main__":
    sys.exit(main())
