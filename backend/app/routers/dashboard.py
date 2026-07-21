from typing import Annotated
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from app.database import get_session
from app.core.deps import get_current_user
from app.models.user import User
from app.models.session import TherapySession, SessionStatus
from app.models.chat import ChatSession, ChatMessage
from app.schemas.dashboard import DashboardData, TriageAlert, StatCounts, ScheduleItem
from datetime import datetime, date

router = APIRouter(prefix="/professional/dashboard", tags=["Professional Dashboard"])

@router.get("", response_model=DashboardData)
def get_dashboard_data(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_session)],
):
    """Get the professional dashboard data scoped strictly to the current professional's assigned clients."""
    if current_user.role != "professional":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only professionals can access the dashboard")
        
    prof_id = current_user.id
    
    # 1. Get all assigned clients (clients who have any TherapySession with this professional)
    assigned_sessions = db.exec(
        select(TherapySession)
        .where(TherapySession.professional_id == prof_id)
    ).all()
    
    assigned_client_ids = list(set([s.client_id for s in assigned_sessions]))
    
    # Active patients = number of distinct assigned clients
    active_patients_count = len(assigned_client_ids)
    
    # Pending requests = scheduled sessions (or a specific pending state if one existed)
    pending_requests_count = len([s for s in assigned_sessions if s.status == SessionStatus.SCHEDULED])
    
    # 2. Get Triage Alerts (Flagged Chat Messages) for ONLY these clients
    alerts = []
    if assigned_client_ids:
        # Get chat sessions for these clients
        chat_sessions = db.exec(
            select(ChatSession).where(ChatSession.user_id.in_(assigned_client_ids))
        ).all()
        chat_session_ids = [cs.id for cs in chat_sessions]
        
        if chat_session_ids:
            flagged_messages = db.exec(
                select(ChatMessage)
                .where(ChatMessage.session_id.in_(chat_session_ids))
                .where(ChatMessage.risk_flag == True)
            ).all()
            
            # Helper to get client name
            client_dict = {}
            for cid in assigned_client_ids:
                u = db.exec(select(User).where(User.id == cid)).first()
                if u:
                    client_dict[cid] = f"{u.first_name} {u.last_name[0]}." if u.first_name else "Unknown Client"
            
            for msg in flagged_messages:
                # Find which client it belongs to
                cs = next((s for s in chat_sessions if s.id == msg.session_id), None)
                if not cs: continue
                client_name = client_dict.get(cs.user_id, "Unknown Client")
                
                # Mock time ago logic for MVP
                time_ago = "Recently"
                delta = datetime.utcnow() - msg.created_at
                if delta.days > 0:
                    time_ago = f"{delta.days} days ago"
                elif delta.seconds > 3600:
                    time_ago = f"{delta.seconds // 3600} hrs ago"
                elif delta.seconds > 60:
                    time_ago = f"{delta.seconds // 60} mins ago"
                
                alerts.append(TriageAlert(
                    id=uuid.uuid4(), # Generate unique id for the alert item itself
                    client_name=client_name,
                    flag_type="High Crisis Flag",
                    description=msg.content[:100] + ("..." if len(msg.content) > 100 else ""),
                    time_ago=time_ago,
                    chat_message_id=msg.id,
                    created_at=msg.created_at
                ))
    
    # Sort alerts by newest first
    alerts.sort(key=lambda x: x.created_at, reverse=True)
    
    # 3. Get Today's Schedule
    today = date.today()
    schedule = []
    
    # Filter assigned_sessions for today and SCHEDULED
    todays_sessions = [
        s for s in assigned_sessions 
        if s.status == SessionStatus.SCHEDULED and s.date_time.date() == today
    ]
    # Sort by time
    todays_sessions.sort(key=lambda x: x.date_time)
    
    for s in todays_sessions:
        u = db.exec(select(User).where(User.id == s.client_id)).first()
        client_name = f"{u.first_name} {u.last_name[0]}." if u and u.first_name else "Unknown Client"
        time_str = s.date_time.strftime("%I:%M %p")
        
        schedule.append(ScheduleItem(
            id=s.id,
            client_name=client_name,
            time=time_str,
            type=s.reason,
            mode="Virtual" if s.mode.lower() == "online" else "In-Person"
        ))

    return DashboardData(
        alerts=alerts,
        stats=StatCounts(
            active_patients=active_patients_count,
            pending_requests=pending_requests_count
        ),
        schedule=schedule
    )
