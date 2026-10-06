import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
try:
    import sentry_sdk
    _sentry_available = True
except ImportError:
    _sentry_available = False

from app.database import create_db_and_tables
from app.routers import auth, mood, chat, admin, notification, articles, crisis, journal

# Initialize Sentry error monitoring if SENTRY_DSN is configured
sentry_dsn = os.getenv("SENTRY_DSN")
if sentry_dsn and _sentry_available:
    sentry_sdk.init(
        dsn=sentry_dsn,
        traces_sample_rate=1.0,
        send_default_pii=False,
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Runs on startup
    create_db_and_tables()
    try:
        from app.migrate_db import migrate
        migrate()
    except Exception:
        pass
    yield
    # Runs on shutdown (add cleanup here if needed later)


app = FastAPI(
    title="Kausap AI API",
    description="Backend API for Kausap AI — Student Mental Health Companion",
    version="0.2.0",
    lifespan=lifespan,
)

# CORS — allow Flutter mobile app and any local dev tools
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?|https://.*\.onrender\.com|https://.*\.vercel\.app",
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# GZip Compression — reduce network bandwidth by up to 80% on slow Wi-Fi
app.add_middleware(GZipMiddleware, minimum_size=1000)


@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "message": "Kausap AI API is running 🚀"}


@app.get("/health", tags=["Health"])
def health():
    """Tiny endpoint for uptime monitors / app warm-up pings."""
    return {"status": "ok"}


@app.get("/health/ai", tags=["Health"])
async def health_ai():
    """Reports whether AI provider keys are configured and whether Gemini answers. Never returns secrets."""
    from app.core.config import settings
    from app.core.ai_provider import chat_completion_with_usage, FALLBACK_REPLY

    info = {
        "gemini_key_configured": bool(settings.GEMINI_API_KEY),
        "mistral_key_configured": bool(settings.MISTRAL_API_KEY),
        "openai_key_configured": bool(settings.OPENAI_API_KEY),
        "elevenlabs_key_configured": bool(settings.ELEVENLABS_API_KEY),
    }
    try:
        text, _, _, _ = await chat_completion_with_usage(
            [{"role": "user", "content": "Reply with the single word: ok"}], max_tokens=20
        )
        info["ai_working"] = text != FALLBACK_REPLY
    except Exception as e:  # pragma: no cover
        info["ai_working"] = False
        info["error"] = str(e)[:120]
    return info


# Routers
app.include_router(auth.router)
app.include_router(mood.router)
app.include_router(chat.router)
app.include_router(admin.router)
app.include_router(notification.router)
app.include_router(articles.router)
app.include_router(articles.admin_router)
app.include_router(crisis.router)
app.include_router(crisis.admin_router)
app.include_router(journal.router)
