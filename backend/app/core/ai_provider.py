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


async def chat_completion(
    messages: list[dict],
    model: str = DEFAULT_MODEL,
    temperature: float = 0.7,
    max_tokens: int = 1024,
) -> str:
    """
    Send a list of messages to the LLM and return the reply as a string.

    Args:
        messages: OpenAI-style message list, e.g.
            [{"role": "system", "content": "..."}, {"role": "user", "content": "..."}]
        model: model name (default: gpt-4o-mini, cheapest GPT-4 class model)
        temperature: creativity 0.0–1.0
        max_tokens: max response length

    Returns:
        The assistant's reply as a plain string.
    """
    response = await _client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
    )
    return response.choices[0].message.content
