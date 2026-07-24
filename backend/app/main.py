from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import create_db_and_tables
from app.routers import auth, mood, chat, referral, admin, session, dashboard, professional, reports, direct_message


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Runs on startup
    create_db_and_tables()
    yield
    # Runs on shutdown (add cleanup here if needed later)


app = FastAPI(
    title="Kausap AI API",
    description="Backend API for Kausap AI — Mental Health Chatbot",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS — allow Flutter mobile app and any local dev tools
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this in production
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
app.include_router(referral.router)
app.include_router(admin.router)
app.include_router(session.router)
app.include_router(dashboard.router)
app.include_router(professional.router)
app.include_router(reports.router)
app.include_router(direct_message.router)
