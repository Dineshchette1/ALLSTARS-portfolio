# app/auth/schemas.py
from pydantic import BaseModel
from enum import Enum
from typing import Optional
from datetime import datetime

class UserRole(str, Enum):
    CUSTOMER = "CUSTOMER"
    ADMIN = "ADMIN"

class UserCreate(BaseModel):
    username: str
    mobile: str

class UserResponse(BaseModel):
    id: int
    username: str
    mobile: str
    role: UserRole
    last_login: Optional[datetime]

    class Config:
        orm_mode = True
