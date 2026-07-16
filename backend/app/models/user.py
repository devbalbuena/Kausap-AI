from datetime import date, datetime
import uuid
from enum import Enum
from typing import Optional, List
from sqlmodel import Field, SQLModel, Relationship


class UserRole(str, Enum):
    client = "client"
    professional = "professional"
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

    # Basic info (shared by all roles)
    first_name: str
    last_name: str
    phone_number: str
    birthday: date
    gender: GenderEnum

    # Optional extras
    address: Optional[str] = Field(default=None)
    bio: Optional[str] = Field(default=None)

    # For clients only — occupation dropdown
    occupation: Optional[OccupationEnum] = Field(default=None)

    created_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationship to professional profile
    professional_profile: Optional["ProfessionalProfile"] = Relationship(back_populates="user")


class ProfessionalProfile(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id", unique=True, index=True)

    profession: str
    prc_license_number: str
    license_url: Optional[str] = Field(default=None)
    specialization: str
    years_of_experience: int
    bio: Optional[str] = Field(default=None)
    is_accepting_clients: bool = Field(default=True)
    location: str

    # Verification — flipped to True by admin only
    is_verified: bool = Field(default=False)

    created_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationship back to user
    user: Optional[User] = Relationship(back_populates="professional_profile")
