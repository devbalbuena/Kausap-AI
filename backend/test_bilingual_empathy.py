"""
test_bilingual_empathy.py
-------------------------
Verifies bilingual (English / Tagalog / Taglish / Bisaya) empathy behaviour of the
clinical guardrails module. Does not touch the database or any AI provider.
Run:  python test_bilingual_empathy.py
"""

import sys

from app.core.clinical_guardrails import (
    build_system_messages,
    check_clinical_boundary,
    detect_student_language,
)

errors = []


def check(condition, msg):
    if condition:
        print(f"  PASS: {msg}")
    else:
        print(f"  FAIL: {msg}")
        errors.append(msg)


print("=== Language detection ===")
for text in [
    "Kumusta ka? Pagod na pagod na ako",
    "sobrang pagod ako ngayon kasi may thesis defense",
    "kapoy kaayo ang exam namo",
    "Ayoko na talaga, hirap na hirap na ko",
    "Salamat po",
]:
    check(detect_student_language(text) == "taglish", f"detected Filipino/Bisaya: {text!r}")

for text in [
    "I feel really stressed about my thesis",
    "I ate lunch alone again today",
    "Hi, how are you?",
    "Please reply in English, pagod na ako",
    "",
]:
    check(detect_student_language(text) == "english", f"detected English: {text!r}")

print("\n=== System prompt: base rules are bilingual, not English-only ===")
base = build_system_messages()[0]["content"]
check("BILINGUAL EMPATHY" in base, "base prompt declares bilingual empathy rules")
check("NO TAGALOG / TAGLISH / BISAYA" not in base, "old English-only ban removed from base prompt")
check("simple English" in base, "safety info stays in clear English")
check("NEVER prescribe" in base, "clinical guardrail (no prescribing) still present")

print("\n=== System prompt: directive follows the student's language ===")
tag = build_system_messages(user_message="Pagod na pagod na ako sa thesis, kapoy kaayo")[0]["content"]
check("[LANGUAGE DIRECTIVE: BILINGUAL EMPATHY" in tag, "Taglish message gets bilingual directive")
check("[LANGUAGE DIRECTIVE: ENGLISH" not in tag, "Taglish message does not get English-only directive")

eng = build_system_messages(user_message="I feel overwhelmed with my thesis")[0]["content"]
check("[LANGUAGE DIRECTIVE: ENGLISH" in eng, "English message gets English directive")
check("[LANGUAGE DIRECTIVE: BILINGUAL EMPATHY" not in eng, "English message does not get bilingual directive")

none_msg = build_system_messages()[0]["content"]
check("[LANGUAGE DIRECTIVE: ENGLISH" in none_msg, "No message defaults to English directive")

print("\n=== Clinical boundaries unaffected ===")
v, _ = check_clinical_boundary("What medicine should I take for panic attacks?")
check(v, "prescription boundary still enforced")
v, _ = check_clinical_boundary("Can you diagnose me with depression?")
check(v, "diagnosis boundary still enforced")
v, _ = check_clinical_boundary("Pagod na ako sa thesis")
check(not v, "plain Taglish venting passes to the AI")

print()
if errors:
    print(f"RESULT: {len(errors)} check(s) FAILED")
    sys.exit(1)
print("RESULT: ALL CHECKS PASSED")
