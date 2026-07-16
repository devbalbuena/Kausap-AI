from typing import Annotated, List
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import Session, select

from app.database import get_session
from app.core.deps import get_current_user, get_current_admin
from app.models.user import User
from app.models.referral import DoctorReferral
from app.schemas.referral import DoctorReferralCreate, DoctorReferralRead, DoctorReferralUpdate

router = APIRouter(prefix="/referrals", tags=["Referrals"])


@router.post("", response_model=DoctorReferralRead, status_code=status.HTTP_201_CREATED)
def create_referral(
    user_id: uuid.UUID,
    payload: DoctorReferralCreate,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    [Admin Only] Create a doctor referral for a specific user.
    """
    # Verify the target user exists
    target_user = session.get(User, user_id)
    if not target_user:
        raise HTTPException(status_code=404, detail="Target user not found")

    referral = DoctorReferral(
        user_id=user_id,
        doctor_name=payload.doctor_name,
        specialty=payload.specialty,
        contact_info=payload.contact_info,
        notes=payload.notes,
    )
    session.add(referral)
    session.commit()
    session.refresh(referral)
    return referral


@router.get("/me", response_model=List[DoctorReferralRead])
def get_my_referrals(
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    [User] List all referrals assigned to the logged-in user.
    """
    return session.exec(
        select(DoctorReferral)
        .where(DoctorReferral.user_id == current_user.id)
        .order_by(DoctorReferral.created_at.desc())
    ).all()


@router.get("", response_model=List[DoctorReferralRead])
def list_all_referrals(
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    """
    [Admin Only] List all referrals across all users.
    """
    return session.exec(
        select(DoctorReferral)
        .order_by(DoctorReferral.created_at.desc())
        .offset(offset)
        .limit(limit)
    ).all()


@router.get("/{referral_id}", response_model=DoctorReferralRead)
def get_referral(
    referral_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    [User/Admin] Get a specific referral. 
    Users can only see their own. Admins can see any.
    """
    referral = session.get(DoctorReferral, referral_id)
    if not referral:
        raise HTTPException(status_code=404, detail="Referral not found")
        
    if current_user.role != "admin" and referral.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your referral")
        
    return referral


@router.patch("/{referral_id}", response_model=DoctorReferralRead)
def update_referral(
    referral_id: uuid.UUID,
    payload: DoctorReferralUpdate,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    [Admin Only] Update an existing referral record.
    """
    referral = session.get(DoctorReferral, referral_id)
    if not referral:
        raise HTTPException(status_code=404, detail="Referral not found")

    if payload.doctor_name is not None:
        referral.doctor_name = payload.doctor_name
    if payload.specialty is not None:
        referral.specialty = payload.specialty
    if payload.contact_info is not None:
        referral.contact_info = payload.contact_info
    if payload.notes is not None:
        referral.notes = payload.notes

    session.add(referral)
    session.commit()
    session.refresh(referral)
    return referral


@router.delete("/{referral_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_referral(
    referral_id: uuid.UUID,
    admin: Annotated[User, Depends(get_current_admin)],
    session: Annotated[Session, Depends(get_session)],
):
    """
    [Admin Only] Delete a referral record.
    """
    referral = session.get(DoctorReferral, referral_id)
    if not referral:
        raise HTTPException(status_code=404, detail="Referral not found")
        
    session.delete(referral)
    session.commit()
