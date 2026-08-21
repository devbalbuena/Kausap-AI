from datetime import date, datetime
import uuid
from typing import Optional
from pydantic import BaseModel, field_validator
from app.models.user import UserRole, GenderEnum, OccupationEnum


class UserCreate(BaseModel):
    # Role — only "client" or "professional" allowed from API
    role: UserRole = UserRole.client

    # Basic info
    email: str
    password: str
    first_name: str
    last_name: str
    phone_number: str
    birthday: date
    gender: GenderEnum

    # Optional extras for all users
    address: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None

    # Client-only
    occupation: Optional[OccupationEnum] = None

    @field_validator("role")
    @classmethod
    def no_admin_self_register(cls, v: UserRole) -> UserRole:
        if v == UserRole.admin:
            raise ValueError("Cannot register as admin — admin accounts must be set manually in the database.")
        return v


class UserRead(BaseModel):
    id: uuid.UUID
    email: str
    role: UserRole
    is_active: bool
    first_name: str
    last_name: str
    phone_number: str
    birthday: date
    gender: GenderEnum
    address: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    occupation: Optional[OccupationEnum] = None
    created_at: datetime

    class Config:
        from_attributes = True


class RegisterRequest(BaseModel):
    """Registration payload for students/clients."""
    role: UserRole = UserRole.client
    email: str
    password: str
    first_name: str
    last_name: str
    phone_number: str
    birthday: date
    gender: GenderEnum
    address: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    occupation: Optional[OccupationEnum] = None

    @field_validator("role")
    @classmethod
    def no_admin_self_register(cls, v: UserRole) -> UserRole:
        if v == UserRole.admin:
            raise ValueError("Cannot register as admin — admin accounts must be set manually in the database.")
        return v


class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[str] = None
    birthday: Optional[date] = None
    gender: Optional[GenderEnum] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
