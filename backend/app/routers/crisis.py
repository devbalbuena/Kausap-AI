import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.database import get_session
from app.models.hotline import EmergencyHotline
from app.models.user import User
from app.models.audit_log import AuditLog
from app.schemas.hotline import HotlineRead, HotlineCreate, HotlineUpdate
from app.core.deps import get_current_counselor_or_admin


router = APIRouter(prefix="/crisis", tags=["Crisis & Hotlines"])
admin_router = APIRouter(prefix="/admin/hotlines", tags=["Admin Hotlines"])

DEFAULT_HOTLINES = [
    {
        "name": "FSUU Guidance Center Emergency Line",
        "phone": "(085) 342-1830",
        "email": "guidance@urios.edu.ph",
        "description": "Main Campus, Father Saturnino Urios University, Butuan City",
        "category": "campus",
        "type": "call",
        "is_active": True,
        "sort_order": 1,
    },
    {
        "name": "National Center for Mental Health (NCMH)",
        "phone": "1553 / 0917-899-8727",
        "email": "ncmh.gov.ph",
        "description": "24/7 National Mental Health Crisis Hotline (Toll-Free Nationwide)",
        "category": "national",
        "type": "call",
        "is_active": True,
        "sort_order": 2,
    },
    {
        "name": "Hopeline Philippines",
        "phone": "0917-558-4673 / (02) 8804-4673",
        "email": "hopeline@ngf-hope.org",
        "description": "24/7 Suicide Prevention & Crisis Support Line",
        "category": "national",
        "type": "call",
        "is_active": True,
        "sort_order": 3,
    },
    {
        "name": "In Touch Community Services",
        "phone": "+63 917 800 1123 / +63 2 8893 7603",
        "email": "crisisline@in-touch.org",
        "description": "Crisis Line Philippines 24/7 Multilingual Support",
        "category": "national",
        "type": "call",
        "is_active": True,
        "sort_order": 4,
    },
    {
        "name": "Philippine Emergency Hotline (911)",
        "phone": "911",
        "email": None,
        "description": "National Emergency First Responders, Police & Ambulance",
        "category": "emergency",
        "type": "call",
        "is_active": True,
        "sort_order": 5,
    },
    {
        "name": "Text Crisis Support Line",
        "phone": "09178626820",
        "email": None,
        "description": "Text HELLO to this number for confidential SMS chat support",
        "category": "national",
        "type": "sms",
        "is_active": True,
        "sort_order": 6,
    },
]


def seed_default_hotlines_if_empty(session: Session) -> None:
    """Seed initial FSUU & National hotlines if the table is currently empty."""
    statement = select(EmergencyHotline).limit(1)
    existing = session.exec(statement).first()
    if not existing:
        for item in DEFAULT_HOTLINES:
            hotline = EmergencyHotline(**item)
            session.add(hotline)
        session.commit()


@router.get("/hotlines", response_model=List[HotlineRead])
@router.get("/hotlines/", response_model=List[HotlineRead])
def get_public_hotlines(
    category: Optional[str] = None,
    session: Session = Depends(get_session),
):
    """Retrieve all active emergency hotlines. Seeds initial campus records if empty."""
    seed_default_hotlines_if_empty(session)

    statement = select(EmergencyHotline).where(EmergencyHotline.is_active == True)
    if category:
        statement = statement.where(EmergencyHotline.category == category)
    
    statement = statement.order_by(EmergencyHotline.sort_order, EmergencyHotline.created_at)
    hotlines = session.exec(statement).all()
    return hotlines


@admin_router.get("", response_model=List[HotlineRead])
@admin_router.get("/", response_model=List[HotlineRead])
def list_admin_hotlines(
    category: Optional[str] = None,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_counselor_or_admin),
):
    """List all emergency hotlines (active & inactive) for counselors and admins."""
    seed_default_hotlines_if_empty(session)

    statement = select(EmergencyHotline)
    if category:
        statement = statement.where(EmergencyHotline.category == category)
    
    statement = statement.order_by(EmergencyHotline.sort_order, EmergencyHotline.created_at)
    return session.exec(statement).all()


@admin_router.post("", response_model=HotlineRead, status_code=status.HTTP_201_CREATED)
@admin_router.post("/", response_model=HotlineRead, status_code=status.HTTP_201_CREATED)
def create_hotline(
    payload: HotlineCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_counselor_or_admin),
):
    """Create a new emergency hotline entry."""
    hotline = EmergencyHotline(
        name=payload.name.strip(),
        phone=payload.phone.strip(),
        email=payload.email.strip() if payload.email else None,
        description=payload.description.strip() if payload.description else None,
        category=payload.category,
        type=payload.type,
        is_active=payload.is_active,
        sort_order=payload.sort_order,
    )
    session.add(hotline)
    session.commit()
    session.refresh(hotline)

    # Log audit entry
    audit = AuditLog(
        admin_id=current_user.id,
        admin_email=current_user.email,
        action="CREATE_HOTLINE",
        target_type="EmergencyHotline",
        target_id=hotline.id,
        details_json=f'{{"name": "{hotline.name}", "phone": "{hotline.phone}", "category": "{hotline.category}"}}',
    )
    session.add(audit)
    session.commit()

    return hotline


@admin_router.put("/{hotline_id}", response_model=HotlineRead)
@admin_router.put("/{hotline_id}/", response_model=HotlineRead)
def update_hotline(
    hotline_id: str,
    payload: HotlineUpdate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_counselor_or_admin),
):
    """Update an existing emergency hotline. Supports UUID lookup, name matching fallback, or upsert."""
    hotline = session.get(EmergencyHotline, hotline_id)
    if not hotline and payload.name:
        # Check by name in case of offline fallback ID
        statement = select(EmergencyHotline).where(EmergencyHotline.name == payload.name.strip())
        hotline = session.exec(statement).first()

    if not hotline:
        # If still not found, create new hotline with payload
        hotline = EmergencyHotline(
            name=payload.name.strip() if payload.name else "Emergency Hotline",
            phone=payload.phone.strip() if payload.phone else "",
            email=payload.email.strip() if payload.email else None,
            description=payload.description.strip() if payload.description else None,
            category=payload.category or "campus",
            type=payload.type or "call",
            is_active=payload.is_active if payload.is_active is not None else True,
            sort_order=payload.sort_order or 1,
        )
        session.add(hotline)
        session.commit()
        session.refresh(hotline)
    else:
        update_data = payload.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            if isinstance(value, str):
                value = value.strip()
            setattr(hotline, key, value)

        hotline.updated_at = datetime.utcnow()
        session.add(hotline)
        session.commit()
        session.refresh(hotline)

    # Log audit entry
    audit = AuditLog(
        admin_id=current_user.id,
        admin_email=current_user.email,
        action="UPDATE_HOTLINE",
        target_type="EmergencyHotline",
        target_id=hotline.id,
        details_json=f'{{"name": "{hotline.name}", "phone": "{hotline.phone}", "is_active": {str(hotline.is_active).lower()}}}',
    )
    session.add(audit)
    session.commit()

    return hotline


@admin_router.delete("/{hotline_id}")
@admin_router.delete("/{hotline_id}/")
def delete_hotline(
    hotline_id: str,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_counselor_or_admin),
):
    """Soft delete an emergency hotline entry (sets is_active = False)."""
    hotline = session.get(EmergencyHotline, hotline_id)
    if not hotline:
        # Fallback by name lookup
        statement = select(EmergencyHotline).where(EmergencyHotline.name == hotline_id)
        hotline = session.exec(statement).first()

    if not hotline:
        raise HTTPException(status_code=404, detail="Emergency hotline not found")

    hotline_name = hotline.name
    hotline.is_active = False  # SOFT DELETE
    hotline.updated_at = datetime.utcnow()
    session.add(hotline)
    session.commit()
    session.refresh(hotline)

    # Log audit entry
    audit = AuditLog(
        admin_id=current_user.id,
        admin_email=current_user.email,
        action="SOFT_DELETE_HOTLINE",
        target_type="EmergencyHotline",
        target_id=hotline.id,
        details_json=f'{{"soft_deleted_name": "{hotline_name}", "is_active": false}}',
    )
    session.add(audit)
    session.commit()

    return {"status": "ok", "message": f"Hotline '{hotline_name}' archived successfully (soft deleted)"}

