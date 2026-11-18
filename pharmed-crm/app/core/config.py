from pathlib import Path
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent.parent
DATA_DIR = BASE_DIR / "data"
DB_PATH = DATA_DIR / "farmed_crm.db"


class Settings(BaseSettings):
    APP_NAME: str = "CRM فروش فارمد پلیمر رایان"
    APP_VERSION: str = "3.0.4"
    ENVIRONMENT: str = "development"
    DEBUG: bool = False

    DATABASE_URL: str = "sqlite:///" + str(DB_PATH).replace("\\", "/")

    SECRET_KEY: str = ""
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    BOOTSTRAP_ADMIN_PASSWORD: str = ""
    BOOTSTRAP_BAYAT_PASSWORD: str = ""
    BOOTSTRAP_MOSTOFI_PASSWORD: str = ""
    BOOTSTRAP_TAVAKOLI_PASSWORD: str = ""

    CORS_ORIGINS: str = "http://localhost:8000,http://127.0.0.1:8000"
    TRUSTED_HOSTS: str = "localhost,127.0.0.1"
    DATA_DIR: Path = DATA_DIR
    BACKUP_DIR: Path = BASE_DIR / "backups"
    FRONTEND_DIR: Path = BASE_DIR / "frontend"

    COMPANY_NAME: str = "فارمد پلیمر رایان"
    DEFAULT_CURRENCY: str = "تومان"

    model_config = SettingsConfigDict(env_file=str(BASE_DIR / ".env"), extra="ignore", case_sensitive=False)

    @property
    def cors_origins(self) -> list[str]:
        return [x.strip() for x in self.CORS_ORIGINS.split(",") if x.strip()]

    @property
    def trusted_hosts(self) -> list[str]:
        return [x.strip() for x in self.TRUSTED_HOSTS.split(",") if x.strip()]

    def validate_security(self) -> None:
        if self.ENVIRONMENT.lower() == "production":
            if len(self.SECRET_KEY) < 32 or "REPLACE_WITH" in self.SECRET_KEY:
                raise ValueError("SECRET_KEY must be set to a strong random value in production")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
