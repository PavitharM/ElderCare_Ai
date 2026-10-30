import uuid
from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from ...core.database import get_db
from ...models.user import User
from ...models.elderly import EmergencyContact
from ...models.emergency import EmergencyIncident, IncidentNotification
from ...schemas.emergency import EmergencyIncidentOut, EmergencyIncidentCreate
from ..deps import get_current_user

router = APIRouter()

@router.post("/fall-detected", response_model=EmergencyIncidentOut)
def record_fall_incident(
    data: EmergencyIncidentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not current_user.elderly_profile:
        raise HTTPException(status_code=400, detail="Only elderly profiles can record emergency incidents")

    incident = EmergencyIncident(
        id=str(uuid.uuid4()),
        elderly_id=current_user.elderly_profile.id,
        incident_type="fall_detected",
        title=data.title,
        description=data.description or "Sudden deceleration registered by wearable sensor.",
        impact_force_g=data.impact_force_g or 2.80,
        location_text=data.location_text,
        latitude=data.latitude,
        longitude=data.longitude,
        severity="critical",
        status="active_countdown",
        triggered_at=datetime.now(timezone.utc),
    )
    db.add(incident)
    db.flush()

    # Create dispatch records for emergency contacts
    contacts = db.query(EmergencyContact).filter(
        EmergencyContact.elderly_id == current_user.elderly_profile.id
    ).all()

    for c in contacts:
        notif = IncidentNotification(
            id=str(uuid.uuid4()),
            incident_id=incident.id,
            contact_name=c.name,
            contact_phone=c.phone,
            channel="sms",
            delivery_status="simulated_sent",
            status_message=f"Simulated emergency SMS queued for {c.name} ({c.phone})",
        )
        db.add(notif)

    db.commit()
    db.refresh(incident)
    return incident

@router.post("/sos", response_model=EmergencyIncidentOut)
def record_manual_sos(
    location_text: str = "Home",
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not current_user.elderly_profile:
        raise HTTPException(status_code=400, detail="Only elderly profiles can trigger manual SOS")

    incident = EmergencyIncident(
        id=str(uuid.uuid4()),
        elderly_id=current_user.elderly_profile.id,
        incident_type="manual_sos",
        title="Manual SOS Triggered",
        description="Elderly pressed 3-second SOS safety latch.",
        location_text=location_text,
        severity="critical",
        status="dispatched",
        triggered_at=datetime.now(timezone.utc),
    )
    db.add(incident)
    db.flush()

    contacts = db.query(EmergencyContact).filter(
        EmergencyContact.elderly_id == current_user.elderly_profile.id
    ).all()

    for c in contacts:
        notif = IncidentNotification(
            id=str(uuid.uuid4()),
            incident_id=incident.id,
            contact_name=c.name,
            contact_phone=c.phone,
            channel="call",
            delivery_status="simulated_sent",
            status_message=f"Simulated emergency auto-dialer queued for {c.name} ({c.phone})",
        )
        db.add(notif)

    db.commit()
    db.refresh(incident)
    return incident

@router.post("/{incident_id}/cancel")
def cancel_false_alarm(
    incident_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    incident = db.query(EmergencyIncident).filter(
        EmergencyIncident.id == incident_id
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    incident.status = "false_alarm"
    incident.resolved_at = datetime.now(timezone.utc)
    db.commit()

    return {"status": "success", "message": "Incident marked as false alarm. Broadcast canceled."}

@router.get("/{incident_id}/status", response_model=EmergencyIncidentOut)
def get_incident_status(
    incident_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    incident = db.query(EmergencyIncident).filter(
        EmergencyIncident.id == incident_id
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    return incident

@router.get("/logs", response_model=List[EmergencyIncidentOut])
def get_incident_logs(
    elderly_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_elderly_id = current_user.elderly_profile.id if current_user.role == "elderly" else elderly_id
    if not target_elderly_id:
        raise HTTPException(status_code=400, detail="Target elderly_id not specified")

    incidents = db.query(EmergencyIncident).filter(
        EmergencyIncident.elderly_id == target_elderly_id
    ).order_by(desc(EmergencyIncident.triggered_at)).all()

    return incidents
