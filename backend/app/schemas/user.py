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

    # Client-only
    occupation: Optional[OccupationEnum] = None

    @field_validator("role")
    @classmethod
    def no_admin_self_register(cls, v: UserRole) -> UserRole:
        if v == UserRole.admin:
            raise ValueError("Cannot register as admin — admin accounts must be set manually in the database.")
        return v


class ProfessionalProfileCreate(BaseModel):
    profession: str
    prc_license_number: str
    license_url: Optional[str] = None
    specialization: str
    years_of_experience: int
    bio: Optional[str] = None
    is_accepting_clients: bool = True
    location: str


class ProfessionalProfileRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    profession: str
    prc_license_number: str
    license_url: Optional[str]
    specialization: str
    years_of_experience: int
    bio: Optional[str]
    is_accepting_clients: bool
    location: str
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True


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
    address: Optional[str]
    bio: Optional[str]
    occupation: Optional[OccupationEnum]
    created_at: datetime
    professional_profile: Optional[ProfessionalProfileRead] = None

    class Config:
        from_attributes = True


class RegisterRequest(BaseModel):
    """Full registration payload — user fields + optional professional profile fields."""
    # User fields
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
    occupation: Optional[OccupationEnum] = None

    # Professional profile fields — required when role == professional
    profession: Optional[str] = None
    prc_license_number: Optional[str] = None
    license_url: Optional[str] = None
    specialization: Optional[str] = None
    years_of_experience: Optional[int] = None
    professional_bio: Optional[str] = None
    is_accepting_clients: Optional[bool] = True
    location: Optional[str] = None

    @field_validator("role")
    @classmethod
    def no_admin_self_register(cls, v: UserRole) -> UserRole:
        if v == UserRole.admin:
            raise ValueError("Cannot register as admin — admin accounts must be set manually in the database.")
        return v
