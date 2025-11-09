from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    cors_origins: str = "*"