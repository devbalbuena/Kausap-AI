from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str
    # Optional: Neon PgBouncer pooled endpoint (e.g. ep-xxx-pooler.ap-southeast-1.aws.neon.tech).
    # If set, all runtime queries use the pooler for lower connection overhead.
    # DDL migrations always use DATABASE_URL (direct endpoint) regardless of this setting.
    DATABASE_POOL_URL: str = ""

    SECRET_KEY: str = "changeme-replace-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day

    # LLM & Voice provider keys
    OPENAI_API_KEY: str = ""
    GEMINI_API_KEY: str = ""
    MISTRAL_API_KEY: str = ""
    ELEVENLABS_API_KEY: str = ""
    ELEVENLABS_VOICE_ID: str = "jqcCZkN6Knx8BJ5TBdYR"

    # Brevo Transactional Email API (for mood check-in notifications)
    # Get your API key from: https://app.brevo.com/settings/keys/api
    BREVO_API_KEY: str = ""
    BREVO_SENDER_EMAIL: str = ""
    BREVO_SENDER_NAME: str = "Kausap AI"

    # Token protection & rate limits
    # Phase 1 tuning: 450 tokens keeps replies concise (~2-3s latency vs ~7s at 1200).
    # 50 msg/hour gives each student generous room during the 45-student mass test.
    RATE_LIMIT_MESSAGES_PER_HOUR: int = 50
    DEFAULT_MAX_TOKENS: int = 450

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
