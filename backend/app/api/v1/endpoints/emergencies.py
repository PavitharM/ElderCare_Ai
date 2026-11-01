from typing import List, Optional

from fastapi import APIRouter, Body, Depends
from sqlalchemy.orm import Session

from ....db.session import get_db
from ....models.elderly import ElderlyProfile
from ....models.user import User
from ....schemas.emergency import EmergencyIncidentCreate, EmergencyIncidentOut, SosRequest
from ....services import emergency, risk
from ...deps import get_current_elderly, get_current_user, target_elderly

router = APIRouter()


@router.post("/fall-detected", response_model=EmergencyIncidentOut)
def record_fall_incident(
    data: EmergencyIncidentCreate,
    elderly: ElderlyProfile = Depends(get_current_elderly),
    db: Session = Depends(get_db),
):
    """Starts the fall confirmation countdown. Caregivers are alerted when it expires (or on /escalate)."""
    incident = emergency.create_fall(
        db,
        elderly,
        impact_g=data.impact_force_g,
        title=data.title,
        description=data.description,
        location_text=data.location_text,
        latitude=data.latitude,
        longitude=data.longitude,
    )
    db.commit()
    db.refresh(incident)
    return incident


@router.post("/sos", response_model=EmergencyIncidentOut)
def record_manual_sos(
    data: Optional[SosRequest] = Body(None),
    elderly: ElderlyProfile = Depends(get_current_elderly),
    db: Session = Depends(get_db),
):
    data = data or SosRequest()
    incident = emergency.create_sos(db, elderly, data.location_text, data.latitude, data.longitude)
    risk.evaluate(db, elderly.id)
    db.commit()
    db.refresh(incident)
    return incident


@router.post("/{incident_id}/escalate", response_model=EmergencyIncidentOut)
def escalate_incident(incident_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """User did not respond (or pressed 'send now'): alert caregivers immediately."""
    incident = emergency.escalate(db, emergency.get_for_user(db, current_user, incident_id))
    risk.evaluate(db, incident.elderly_id)
    db.commit()
    db.refresh(incident)
    return incident


@router.post("/{incident_id}/cancel")
def cancel_false_alarm(incident_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    incident = emergency.cancel(db, emergency.get_for_user(db, current_user, incident_id))
    db.commit()
    return {"status": "success", "incident_status": incident.status, "message": "Incident marked as false alarm."}


@router.post("/{incident_id}/resolve", response_model=EmergencyIncidentOut)
def resolve_incident(incident_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Caregiver (or user) confirms the situation is handled."""
    incident = emergency.resolve(db, emergency.get_for_user(db, current_user, incident_id))
    db.commit()
    db.refresh(incident)
    return incident


@router.get("/{incident_id}/status", response_model=EmergencyIncidentOut)
def get_incident_status(incident_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    incident = emergency.get_for_user(db, current_user, incident_id)
    emergency.escalate_due(db, [incident.elderly_id])
    db.refresh(incident)
    return incident


@router.get("/logs", response_model=List[EmergencyIncidentOut])
def get_incident_logs(elderly: ElderlyProfile = Depends(target_elderly()), db: Session = Depends(get_db)):
    emergency.escalate_due(db, [elderly.id])
    return emergency.list_for_elderly(db, elderly.id)
