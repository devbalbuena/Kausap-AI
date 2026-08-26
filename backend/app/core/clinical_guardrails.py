"""
clinical_guardrails.py
-----------------------
Ethical AI Boundary Enforcement for Kausap AI (NFR — Ethical AI Guardrails).

This module enforces strict clinical safety boundaries by:
  1. Providing the hardened system prompt injected into every AI conversation.
  2. Detecting when a student is requesting formal medical diagnosis or prescription.
  3. Returning a compassionate clinical boundary response when a violation is detected.

Kausap AI is a wellness COMPANION — not a licensed clinician.
It MUST NEVER:
  - Prescribe or recommend specific medications or drug dosages.
  - Issue formal psychiatric/psychological diagnoses (e.g. "You have depression").
  - Claim to replace licensed counselors, psychologists, or psychiatrists.

All guardrail logic lives here so changes to AI boundaries only require
editing this single file (Layered Architecture — NFR Clean Code).
"""

import re
from typing import Optional

# ─────────────────────────────────────────────────────────────────────────────
# HARDENED SYSTEM PROMPT
# Injected as the FIRST system message in every AI conversation.
# This anchors the AI's identity and hard clinical limits regardless of
# what the student later says (including jailbreak attempts).
# ─────────────────────────────────────────────────────────────────────────────
KAUSAP_SYSTEM_PROMPT = """You are Kausap, a compassionate AI mental wellness companion created for university students at Father Saturnino Urios University (FSUU), Butuan City, Philippines. Your role is to provide emotional support, evidence-based coping strategies, and a non-judgmental space for students to express how they feel.

IDENTITY AND HARD LIMITS — YOU MUST ALWAYS FOLLOW THESE:
1. You are NOT a licensed psychologist, psychiatrist, physician, or mental health professional.
2. You MUST NEVER prescribe, recommend, or suggest any specific medication, drug, supplement, or dosage — even if the student explicitly asks you to.
3. You MUST NEVER issue a formal mental health or medical diagnosis. Do not say things like "You have depression", "You seem to have anxiety disorder", "This sounds like ADHD", or any similar statements that imply a clinical diagnosis.
4. If a student asks you to diagnose them or recommend medication, you MUST warmly decline and redirect them to the FSUU Guidance & Counseling Office or a licensed mental health professional.
5. You may acknowledge symptoms the student shares (e.g., "It sounds like you've been feeling very low lately") but never label them as a disorder.
6. You are a safe space — warm, empathetic, non-judgmental, and culturally sensitive to Filipino student life.
7. You may provide general psychoeducation (e.g., explain what anxiety commonly feels like) but frame it as educational, not diagnostic.
8. You speak in a warm, calm, and supportive tone. You use simple language. You are not clinical or cold.
9. You respect student privacy and never encourage sharing more personal information than the student is comfortable with.

WHEN TO ESCALATE:
- If a student expresses thoughts of suicide, self-harm, or harming others, immediately provide crisis hotlines and encourage them to contact FSUU Guidance & Counseling or call 1553 (NCMH Hopeline).

CULTURAL CONTEXT:
- Students are Filipino university students navigating academic pressure, family expectations, and life transitions.
- Be sensitive to Filipino values, language mixing (Taglish is welcome), and the cultural stigma around mental health.

Remember: You are a companion, not a clinician. Your job is to listen, support, and guide students toward professional help when needed."""


# ─────────────────────────────────────────────────────────────────────────────
# CLINICAL BOUNDARY TRIGGER PATTERNS
# These detect when a student is requesting prescription or formal diagnosis.
# Compiled once at module import for performance (NFR — Performance).
# ─────────────────────────────────────────────────────────────────────────────
_PRESCRIPTION_PATTERNS = [
    # Medication requests
    r"\bwhat (medication|medicine|drug|pill|meds?|antidepressant|antipsychotic|ssri|snri|benzo|sleeping pill)\b",
    r"\bshould (i|we) take\b.*\b(medication|medicine|drug|pill|meds?)\b",
    r"\bprescribe\b",
    r"\bprescription\b",
    r"\bcan (you|kausap) (give|prescribe|recommend|suggest) (me )?(medication|medicine|meds?|drug)\b",
    r"\bwhat (dose|dosage|mg|milligram)\b",
    r"\bhow much (medication|medicine|drug|pill)\b",
    r"\bis (it )?safe to take\b",
    r"\bcan i (take|use|drink)\b.*\b(medication|medicine|drug|pill|meds?|tablet|capsule)\b",
    r"\bmaganda bang uminom ng\b",        # Filipino: "Is it okay to take"
    r"\bang gamot\b",                      # Filipino: "the medicine"
    r"\bang tamang gamot\b",               # Filipino: "the right medicine"
]

_DIAGNOSIS_PATTERNS = [
    # Formal diagnosis requests
    r"\bdo i have\b.*\b(depression|anxiety|adhd|bipolar|ocd|ptsd|schizophrenia|disorder|syndrome|condition)\b",
    r"\bam i (depressed|anxious|bipolar|psychotic|schizophrenic|autistic|neurodivergent)\b",
    r"\bdiagnose (me|us)\b",
    r"\bdiagnosis\b.*\b(for me|of mine|i have)\b",
    r"\bwhat disorder do i have\b",
    r"\bwhat (is|could be) wrong with me\b",
    r"\bdo i (suffer from|have)\b.*\b(disorder|condition|syndrome)\b",
    r"\bsigns of\b.*\b(depression|anxiety|adhd|bipolar|ocd|ptsd|schizophrenia)\b.*\b(do i have|i have|am i)\b",
    r"\bi think i have\b.*\b(depression|anxiety|adhd|bipolar|ocd|ptsd|schizophrenia|disorder)\b",
    r"\bmayroon ba akong\b",               # Filipino: "Do I have"
    r"\bmay (disorder|sakit sa isip|problema sa isip)\b",  # Filipino mental health phrases
    r"\biba ba ako\b",                     # Filipino: "Am I different/abnormal"
]

# Pre-compile all patterns for efficiency
_COMPILED_PRESCRIPTION = [re.compile(p, re.IGNORECASE) for p in _PRESCRIPTION_PATTERNS]
_COMPILED_DIAGNOSIS = [re.compile(p, re.IGNORECASE) for p in _DIAGNOSIS_PATTERNS]


# ─────────────────────────────────────────────────────────────────────────────
# BOUNDARY RESPONSE MESSAGES
# Warm, non-dismissive responses that redirect without being cold or robotic.
# ─────────────────────────────────────────────────────────────────────────────
PRESCRIPTION_BOUNDARY_RESPONSE = """I really appreciate you trusting me with this, and I can hear that you're looking for relief. However, I'm not a doctor or pharmacist, and recommending or prescribing medications isn't something I'm able to do — not because I don't care, but because doing so without proper clinical evaluation could genuinely put your health at risk.

What I'd strongly encourage is speaking with a licensed professional who can properly evaluate what you need:

🏥 **FSUU Guidance & Counseling Center** — Father Saturnino Urios University
📍 Guidance and Testing Center, FSUU Main Campus, San Francisco St., Butuan City
📞 (085) 342-1830 / (085) 815-3208
📧 guidance@urios.edu.ph

💊 **If you're currently taking medication and have questions about it**, your prescribing doctor or a pharmacist is the right person to ask.

In the meantime, I'm here to help you with what I *can* do — talking through how you're feeling, coping strategies, stress management, and just being someone to listen. Would you like to share more about what's been going on? 💙"""


DIAGNOSIS_BOUNDARY_RESPONSE = """I'm really glad you felt comfortable enough to ask, and I want to take what you're sharing seriously. What you're experiencing sounds genuinely difficult, and your feelings are completely valid.

However, I'm not able to diagnose you — not because your question isn't important, but because a proper mental health diagnosis requires a comprehensive clinical assessment by a licensed psychologist or psychiatrist. Me attempting to label what you're experiencing without that full picture could actually be harmful, and I'd never want to mislead you about something this important.

What I *can* tell you is that **reaching out is already a courageous first step**. Here's what I'd suggest:

🧠 **FSUU Guidance & Counseling Center** — They provide free, confidential mental health support and assessments for Urian students.
📍 Guidance and Testing Center, FSUU Main Campus, San Francisco St., Butuan City
📞 (085) 342-1830 / (085) 815-3208
📧 guidance@urios.edu.ph

💬 **National Center for Mental Health (NCMH) Hopeline** — 1553 (Toll-Free, 24/7)

I'm also here to listen right now. You don't need a label to have your feelings validated. Would you like to talk about what you've been experiencing? Sometimes just putting it into words helps. 💙"""


def check_clinical_boundary(text: str) -> tuple[bool, str | None]:
    """
    Check if a student message is requesting prescription or formal diagnosis.

    This is the primary guardrail function called BEFORE sending to the AI.
    If a boundary violation is detected, the AI is skipped entirely and the
    pre-written boundary response is returned instead.

    Args:
        text: The student's raw message content.

    Returns:
        A tuple of (is_violation: bool, response_message: str | None).
        If is_violation is True, response_message contains the boundary response.
        If is_violation is False, response_message is None — proceed normally.
    """
    text_lower = text.lower()

    # Check prescription boundary first (higher clinical risk)
    for pattern in _COMPILED_PRESCRIPTION:
        if pattern.search(text_lower):
            return True, PRESCRIPTION_BOUNDARY_RESPONSE

    # Check diagnosis boundary
    for pattern in _COMPILED_DIAGNOSIS:
        if pattern.search(text_lower):
            return True, DIAGNOSIS_BOUNDARY_RESPONSE

    return False, None


def build_system_messages(user_context: Optional[str] = None) -> list[dict]:
    """
    Return the hardened system message list that must always be prepended
    to every LLM conversation. This ensures the system prompt cannot be
    overridden by user messages.
    """
    prompt = KAUSAP_SYSTEM_PROMPT
    if user_context:
        prompt += f"\n\n[STUDENT CULTURAL & PERSONAL PROFILE]\n{user_context}\nUse this cultural and personal context naturally to be relatable and empathetic to Filipino university student life, without diagnosing or prescribing."
    return [{"role": "system", "content": prompt}]
