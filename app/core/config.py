from pydantic_settings import BaseSettings



class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+psycopg2://postgres:CHANGE_ME@localhost:5432/capstone_db2"
    SECRET_KEY: str = "CHANGE_ME_SECRET_KEY"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 30

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
