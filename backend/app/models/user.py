from datetime import date, datetime
import uuid
from enum import Enum
from typing import Optional, List
from sqlmodel import Field, SQLModel, Relationship


class UserRole(str, Enum):
    client = "client"
    admin = "admin"


class GenderEnum(str, Enum):
    male = "Male"
    female = "Female"
    non_binary = "Non-binary"
    prefer_not_to_say = "Prefer not to say"
    other = "Other"


class OccupationEnum(str, Enum):
    student = "Student"
    employed = "Employed"
    self_employed = "Self-employed"
    unemployed = "Unemployed"
    other = "Other"


class User(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)

    # Auth
    email: str = Field(unique=True, index=True)
    hashed_password: str

    # Role & Status
    role: UserRole = Field(default=UserRole.client)
    is_active: bool = Field(default=True)

    # Basic info
    first_name: str
    last_name: str
    phone_number: str
    birthday: date
    gender: GenderEnum

    # Optional extras
    address: Optional[str] = Field(default=None)
    bio: Optional[str] = Field(default=None)
    avatar_url: Optional[str] = Field(default=None)

    # For students/clients — occupation dropdown
    occupation: Optional[OccupationEnum] = Field(default=None)

    created_at: datetime = Field(default_factory=datetime.utcnow)

    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}".strip()
