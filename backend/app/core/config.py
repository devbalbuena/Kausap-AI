from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str
    SECRET_KEY: str = "changeme-replace-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day

    # LLM & Voice provider keys
    OPENAI_API_KEY: str = ""
    GEMINI_API_KEY: str = ""
    MISTRAL_API_KEY: str = ""
    ELEVENLABS_API_KEY: str = ""
    ELEVENLABS_VOICE_ID: str = "jqcCZkN6Knx8BJ5TBdYR"

    # Token protection & rate limits
    RATE_LIMIT_MESSAGES_PER_HOUR: int = 30
    DEFAULT_MAX_TOKENS: int = 1200

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
