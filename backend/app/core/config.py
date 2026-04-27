from functools import lru_cache
from typing import Annotated, Literal
from urllib.parse import quote

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    app_name: str = "Gokce Toptan"
    app_env: Literal["development", "staging", "production"] = "development"
    app_debug: bool = False
    app_timezone: str = "Europe/Istanbul"

    backend_host: str = "0.0.0.0"
    backend_port: int = 8000
    backend_cors_origins: Annotated[list[str], NoDecode] = Field(default_factory=list)

    # DATABASE_URL / DATABASE_SYNC_URL override'ı. Verilmezse DB_HOST/PORT/USER/PASSWORD/NAME'den üretilir.
    # ECS/Fargate'de her alan ayrı secret olarak enjekte edildiği için bu fallback gerekli.
    database_url: str | None = None
    database_sync_url: str | None = None

    db_host: str | None = None
    db_port: int = 5432
    db_user: str | None = None
    db_password: str | None = None
    db_name: str | None = None

    jwt_secret: str
    jwt_algorithm: str = "HS256"
    jwt_access_token_minutes: int = 30
    jwt_refresh_token_days: int = 14

    argon2_time_cost: int = 3
    argon2_memory_cost: int = 65536
    argon2_parallelism: int = 4

    aws_region: str = "eu-central-1"
    s3_bucket: str = "gokce-toptan-products"
    s3_presign_expires: int = 600
    aws_access_key_id: str | None = None
    aws_secret_access_key: str | None = None

    rate_limit_login: str = "5/minute"
    rate_limit_refresh: str = "30/minute"
    rate_limit_upload: str = "60/minute"

    @field_validator("backend_cors_origins", mode="before")
    @classmethod
    def parse_cors(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, str):
            return [o.strip() for o in v.split(",") if o.strip()]
        return v

    @model_validator(mode="after")
    def _assemble_db_url(self) -> "Settings":
        if not self.database_url:
            if not (self.db_host and self.db_user and self.db_password and self.db_name):
                raise ValueError(
                    "Database config eksik: DATABASE_URL ya da DB_HOST/DB_USER/DB_PASSWORD/DB_NAME ver"
                )
            pw = quote(self.db_password, safe="")
            user = quote(self.db_user, safe="")
            self.database_url = (
                f"postgresql+asyncpg://{user}:{pw}@{self.db_host}:{self.db_port}/{self.db_name}"
            )
        if not self.database_sync_url:
            if self.db_host and self.db_user and self.db_password and self.db_name:
                pw = quote(self.db_password, safe="")
                user = quote(self.db_user, safe="")
                self.database_sync_url = (
                    f"postgresql+psycopg2://{user}:{pw}@{self.db_host}:{self.db_port}/{self.db_name}"
                )
            else:
                # async url'den türet
                self.database_sync_url = self.database_url.replace(
                    "postgresql+asyncpg", "postgresql+psycopg2"
                )
        return self

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]


settings = get_settings()
