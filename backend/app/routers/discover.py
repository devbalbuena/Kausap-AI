from typing import Annotated, List, Optional
import uuid
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session, select, or_
from pydantic import BaseModel

from app.database import get_session
from app.core.deps import get_current_user
from app.models.user import User, ProfessionalProfile

router = APIRouter(prefix="/discover", tags=["Discover"])

class DiscoverProfessionalRead(BaseModel):
    user_id: uuid.UUID
    first_name: str
    last_name: str
    profession: str
    specialization: str
    years_of_experience: int
    bio: Optional[str] = None
    location: str
    is_verified: bool
    is_accepting_clients: bool


@router.get("/professionals", response_model=List[DiscoverProfessionalRead])
def get_professionals(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
    search: Optional[str] = None,
    specialization: Optional[str] = None,
):
    """
    Search and discover verified mental health professionals.
    """
    query = (
        select(User, ProfessionalProfile)
        .join(ProfessionalProfile, User.id == ProfessionalProfile.user_id)
        .where(User.role == "professional")
        .where(ProfessionalProfile.is_verified == True)
        .where(ProfessionalProfile.is_accepting_clients == True)
    )

    if specialization and specialization.lower() != "all":
        query = query.where(ProfessionalProfile.specialization.ilike(f"%{specialization}%"))
    
    if search:
        query = query.where(
            or_(
                User.first_name.ilike(f"%{search}%"),
                User.last_name.ilike(f"%{search}%"),
                ProfessionalProfile.profession.ilike(f"%{search}%"),
                ProfessionalProfile.specialization.ilike(f"%{search}%"),
            )
        )

    results = db.exec(query).all()
    
    response = []
    for user, profile in results:
        response.append(DiscoverProfessionalRead(
            user_id=user.id,
            first_name=user.first_name,
            last_name=user.last_name,
            profession=profile.profession,
            specialization=profile.specialization,
            years_of_experience=profile.years_of_experience,
            bio=profile.bio,
            location=profile.location,
            is_verified=profile.is_verified,
            is_accepting_clients=profile.is_accepting_clients,
        ))
    
    return response


@router.get("/professionals/{user_id}", response_model=DiscoverProfessionalRead)
def get_professional_details(
    user_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """
    Get detailed profile of a specific professional.
    """
    result = db.exec(
        select(User, ProfessionalProfile)
        .join(ProfessionalProfile, User.id == ProfessionalProfile.user_id)
        .where(User.id == user_id)
    ).first()
    
    if not result:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Professional not found")
        
    user, profile = result
    
    return DiscoverProfessionalRead(
        user_id=user.id,
        first_name=user.first_name,
        last_name=user.last_name,
        profession=profile.profession,
        specialization=profile.specialization,
        years_of_experience=profile.years_of_experience,
        bio=profile.bio,
        location=profile.location,
        is_verified=profile.is_verified,
        is_accepting_clients=profile.is_accepting_clients,
    )
