import json
from functools import lru_cache
from pathlib import Path
from typing import List, Literal, Optional, Union

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parents[2]
DEV_SECRET_KEY = "dev-only-insecure-secret-change-me"


class Settings(BaseSettings):
    ENVIRONMENT: Literal["development", "production"] = "development"
    PROJECT_NAME: str = "ElderGuard AI API"
    VERSION: str = "1.1.0"
    API_V1_STR: str = "/api/v1"

    # Public URL the hospital QR code points to (must be reachable from clinic devices)
    PUBLIC_BASE_URL: str = "http://localhost:8000"
    # Local timezone used for medication schedules (scheduled times are wall-clock times)
    TIMEZONE: str = "Asia/Colombo"

    # Database
    DATABASE_URL: str = "mysql+pymysql://root:@127.0.0.1:3306/elderguard_db"

    # JWT & Auth
    SECRET_KEY: str = DEV_SECRET_KEY
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    # CORS
    CORS_ORIGINS: Union[List[str], str] = ["*"]

    # Domain rules
    QR_TOKEN_TTL_HOURS: int = 24
    VITAL_STALE_AFTER_MINUTES: int = 15
    FALL_CONFIRM_SECONDS: int = 25
    MEDICATION_MISSED_GRACE_MINUTES: int = 120

    # Push notifications: leave empty to use the simulated (log) sender
    FCM_CREDENTIALS_FILE: Optional[str] = None

    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            v = v.strip()
            return json.loads(v) if v.startswith("[") else [i.strip() for i in v.split(",") if i.strip()]
        return v

    @model_validator(mode="after")
    def check_production_secrets(self):
        if self.ENVIRONMENT == "production" and self.SECRET_KEY == DEV_SECRET_KEY:
            raise ValueError("SECRET_KEY must be set to a strong random value in production")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
