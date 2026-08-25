"""
ai_provider.py
--------------
Single abstraction layer for LLM calls.
All chatbot routers call `chat_completion()` from here.
To switch providers (e.g. OpenAI → Gemini), edit ONLY this file.
"""

from openai import AsyncOpenAI
from app.core.config import settings

# Initialise the client once at import time
_client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

# Default model — override per-call if needed
DEFAULT_MODEL = "gpt-4o-mini"


def calculate_cost_usd(prompt_tokens: int, completion_tokens: int, model: str = DEFAULT_MODEL) -> float:
    """Calculate estimated cost in USD based on OpenAI token pricing."""
    if "gpt-4o-mini" in model:
        # $0.15 / 1M prompt, $0.60 / 1M completion
        return (prompt_tokens * 0.00000015) + (completion_tokens * 0.00000060)
    elif "gpt-4o" in model:
        return (prompt_tokens * 0.00000250) + (completion_tokens * 0.00001000)
    else:
        return (prompt_tokens * 0.00000015) + (completion_tokens * 0.00000060)


async def chat_completion_with_usage(
    messages: list[dict],
    model: str = DEFAULT_MODEL,
    temperature: float = 0.7,
    max_tokens: int = 1024,
) -> tuple[str, int, int, int]:
    """
    Send a list of messages to the LLM and return:
    (assistant_reply, prompt_tokens, completion_tokens, total_tokens)
    """
    response = await _client.chat.completions.create(
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


async def chat_completion(
    messages: list[dict],
    model: str = DEFAULT_MODEL,
    temperature: float = 0.7,
    max_tokens: int = 1024,
) -> str:
    """
    Send a list of messages to the LLM and return the reply as a string.
    """
    content, _, _, _ = await chat_completion_with_usage(
        messages=messages,
        model=model,
        temperature=temperature,
        max_tokens=max_tokens,
    )
    return content

