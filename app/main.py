from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import create_db_and_tables

app = FastAPI(
    title="Kausap AI API",
    description="Backend API for Kausap AI - Filipino Language Learning App",
    version="0.1.0",
)

# CORS — allow Flutter mobile app and any local dev tools
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    create_db_and_tables()


@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "message": "Kausap AI API is running 🚀"}
