import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import sentry_sdk
from app.database import create_db_and_tables
from app.routers import auth, mood, chat, admin, notification, articles, crisis, journal

# Initialize Sentry error monitoring if SENTRY_DSN is configured
sentry_dsn = os.getenv("SENTRY_DSN")
if sentry_dsn:
    sentry_sdk.init(
        dsn=sentry_dsn,
        traces_sample_rate=1.0,
        send_default_pii=False,
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Runs on startup
    create_db_and_tables()
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


@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "message": "Kausap AI API is running 🚀"}


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
