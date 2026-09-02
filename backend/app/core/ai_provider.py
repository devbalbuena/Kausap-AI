"""
ai_provider.py
--------------
Dual-Provider LLM abstraction layer for Kausap AI (Gemini 2.5 Flash + OpenAI Fallback).
Guarantees high availability, low latency, and robust token usage tracking for student mental health.
"""

import logging
from typing import List, Dict, Tuple, Optional
import httpx
from openai import AsyncOpenAI
from app.core.config import settings

logger = logging.getLogger("kausap.ai_provider")

# Initialize OpenAI client if key is set
_openai_client: Optional[AsyncOpenAI] = (
    AsyncOpenAI(api_key=settings.OPENAI_API_KEY) if settings.OPENAI_API_KEY else None
)

# Preferred default models
GEMINI_MODEL = "gemini-2.5-flash"
OPENAI_MODEL = "gpt-4o-mini"


def calculate_cost_usd(prompt_tokens: int, completion_tokens: int, model: str = GEMINI_MODEL) -> float:
    """Calculate estimated cost in USD based on provider pricing."""
    if "gemini" in model.lower():
        # Gemini 2.5 Flash: $0.075 / 1M prompt, $0.30 / 1M completion
        return (prompt_tokens * 0.000000075) + (completion_tokens * 0.00000030)
    elif "gpt-4o-mini" in model.lower():
        # $0.15 / 1M prompt, $0.60 / 1M completion
        return (prompt_tokens * 0.00000015) + (completion_tokens * 0.00000060)
    elif "gpt-4o" in model.lower():
        return (prompt_tokens * 0.00000250) + (completion_tokens * 0.00001000)
    return (prompt_tokens * 0.00000010) + (completion_tokens * 0.00000040)


async def _call_gemini(
    messages: List[Dict[str, str]],
    model: str = GEMINI_MODEL,
    temperature: float = 0.7,
    max_tokens: int = 600,
) -> Tuple[str, int, int, int]:
    """Call Google Gemini 2.5 REST API."""
    if not settings.GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY is not configured")

    # Separate system instruction from conversation history
    system_text = ""
    contents = []

    for msg in messages:
        role = msg.get("role", "user")
        content = msg.get("content", "")

        if role == "system":
            if system_text:
                system_text += "\n\n" + content
            else:
                system_text = content
        elif role == "user":
            contents.append({"role": "user", "parts": [{"text": content}]})
        elif role == "assistant":
            contents.append({"role": "model", "parts": [{"text": content}]})

    payload = {
        "contents": contents,
        "generationConfig": {
            "temperature": temperature,
            "maxOutputTokens": max_tokens,
            "topP": 0.95,
        },
    }

    if system_text:
        payload["systemInstruction"] = {
            "parts": [{"text": system_text}]
        }

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={settings.GEMINI_API_KEY}"

    async with httpx.AsyncClient(timeout=25.0) as client:
        res = await client.post(url, json=payload)
        if res.status_code != 200:
            logger.warning(f"Gemini API error {res.status_code} on {model}: {res.text[:200]}")
            raise RuntimeError(f"Gemini API returned status {res.status_code}")

        data = res.json()
        candidates = data.get("candidates", [])
        if not candidates:
            raise RuntimeError("Gemini returned empty candidates")

        text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")
        usage = data.get("usageMetadata", {})
        prompt_tokens = usage.get("promptTokenCount", 0)
        completion_tokens = usage.get("candidatesTokenCount", 0)
        total_tokens = usage.get("totalTokenCount", prompt_tokens + completion_tokens)

        return text, prompt_tokens, completion_tokens, total_tokens


async def _call_openai(
    messages: List[Dict[str, str]],
    model: str = OPENAI_MODEL,
    temperature: float = 0.7,
    max_tokens: int = 600,
) -> Tuple[str, int, int, int]:
    """Call OpenAI Chat Completions API."""
    if not _openai_client or not settings.OPENAI_API_KEY:
        raise ValueError("OPENAI_API_KEY is not configured")

    response = await _openai_client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
    )
    content = response.choices[0].message.content or ""
    prompt_tokens = response.usage.prompt_tokens if response.usage else 0
    completion_tokens = response.usage.completion_tokens if response.usage else 0
    total_tokens = response.usage.total_tokens if response.usage else (prompt_tokens + completion_tokens)
    return content, prompt_tokens, completion_tokens, total_tokens


async def _call_mistral(
    messages: List[Dict[str, str]],
    model: str = "mistral-small-latest",
    temperature: float = 0.7,
    max_tokens: int = 600,
) -> Tuple[str, int, int, int]:
    """Call Mistral AI REST API (Mistral Studio / Voxtral)."""
    if not settings.MISTRAL_API_KEY:
        raise ValueError("MISTRAL_API_KEY is not configured")

    headers = {
        "Authorization": f"Bearer {settings.MISTRAL_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    url = "https://api.mistral.ai/v1/chat/completions"

    async with httpx.AsyncClient(timeout=25.0) as client:
        res = await client.post(url, headers=headers, json=payload)
        if res.status_code != 200:
            logger.warning(f"Mistral API error {res.status_code}: {res.text[:200]}")
            raise RuntimeError(f"Mistral API returned status {res.status_code}")

        data = res.json()
        choices = data.get("choices", [])
        if not choices:
            raise RuntimeError("Mistral returned empty choices")

        content = choices[0].get("message", {}).get("content", "")
        usage = data.get("usage", {})
        prompt_tokens = usage.get("prompt_tokens", 0)
        completion_tokens = usage.get("completion_tokens", 0)
        total_tokens = usage.get("total_tokens", prompt_tokens + completion_tokens)
        return content, prompt_tokens, completion_tokens, total_tokens


async def chat_completion_with_usage(
    messages: List[Dict[str, str]],
    model: str = GEMINI_MODEL,
    temperature: float = 0.7,
    max_tokens: int = 600,
) -> Tuple[str, int, int, int]:
    """
    Send messages with automatic multi-provider resilience:
    1. Try Gemini 2.5 Flash
    2. Try Gemini 2.5 Pro (if Flash is busy)
    3. Try Mistral AI / Voxtral (mistral-small-latest)
    4. Try OpenAI (gpt-4o-mini)
    5. If all fail, return compassionate safety fallback
    """
    # 1. Try Gemini primary (2.5-flash) and secondary (2.5-pro)
    if settings.GEMINI_API_KEY:
        for gemini_model in [GEMINI_MODEL, "gemini-2.5-pro"]:
            try:
                return await _call_gemini(
                    messages=messages,
                    model=gemini_model,
                    temperature=temperature,
                    max_tokens=max_tokens,
                )
            except Exception as e:
                logger.warning(f"Gemini API ({gemini_model}) failed: {e}. Trying next...")

    # 2. Try Mistral AI fallback (High-speed Mistral / Voxtral)
    if settings.MISTRAL_API_KEY:
        try:
            return await _call_mistral(
                messages=messages,
                model="mistral-small-latest",
                temperature=temperature,
                max_tokens=max_tokens,
            )
        except Exception as e:
            logger.warning(f"Mistral API fallback failed: {e}. Trying OpenAI...")

    # 3. Try OpenAI fallback
    if settings.OPENAI_API_KEY:
        try:
            return await _call_openai(
                messages=messages,
                model=OPENAI_MODEL,
                temperature=temperature,
                max_tokens=max_tokens,
            )
        except Exception as e:
            logger.error(f"OpenAI fallback failed: {e}")

    # 4. Empathetic offline fallback response if all providers are unreachable
    fallback_text = (
        "Nandito pa rin ako para sa'yo. Pasensya na, medyo mabagal ang aking connection "
        "ngayong sandali, pero gusto kong malaman mo na valid at mahalaga ang nararamdaman mo. "
        "Subukan nating huminga nang malalim nang ilang ulit habang nag-aayos ang system. "
        "Kung kailangan mo ng agarang kausap, nandito ang FSUU Guidance Office o tumawag sa NCMH 1553."
    )
    return fallback_text, 0, 0, 0


async def chat_completion(
    messages: List[Dict[str, str]],
    model: str = GEMINI_MODEL,
    temperature: float = 0.7,
    max_tokens: int = 600,
) -> str:
    """Send a list of messages and return the reply string."""
    content, _, _, _ = await chat_completion_with_usage(
        messages=messages,
        model=model,
        temperature=temperature,
        max_tokens=max_tokens,
    )
    return content
