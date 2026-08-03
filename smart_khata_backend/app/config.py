import os
from pydantic import BaseModel

try:
    from pydantic_settings import BaseSettings
except ImportError:
    class BaseSettings(BaseModel):
        pass

class Settings(BaseSettings):
    MONGO_URI: str = os.getenv("MONGO_URI", "mongodb://localhost:27017")
    DATABASE_NAME: str = os.getenv("DATABASE_NAME", "smart_khata_db")
    SECRET_KEY: str = os.getenv("SECRET_KEY", "smart_khata_secret_key_change_in_production_123456789")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
