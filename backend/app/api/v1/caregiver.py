import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from ...core.database import get_db
from ...models.user import User
from ...models.elderly import ElderlyProfile, EmergencyContact
from ...models.caregiver import CaregiverProfile, CaregiverElderlyLink
from ...models.vitals import HealthVital, WearableDevice
from ...models.emergency import EmergencyIncident
from ...models.ai_risk import RiskAssessment
from ...schemas.caregiver import CaregiverProfileOut, LinkElderlyRequest, LinkedElderlyCard
from ..deps import get_current_user, require_role

router = APIRouter()

@router.get("/portal")
def get_caregiver_portal(
    current_user: User = Depends(require_role(["caregiver"])),
    db: Session = Depends(get_db)
):
    profile = current_user.caregiver_profile
    if not profile:
        raise HTTPException(status_code=404, detail="Caregiver profile not found")

    links = db.query(CaregiverElderlyLink).filter(
        CaregiverElderlyLink.caregiver_id == profile.id,
        CaregiverElderlyLink.status == "active"
    ).all()

    elderly_cards = []
    active_incidents = []

    for link in links:
        elderly = link.elderly
        if not elderly:
            continue

        # Get latest vitals
        hr = db.query(HealthVital).filter(
            HealthVital.elderly_id == elderly.id,
            HealthVital.metric_type == "heart_rate"
        ).order_by(desc(HealthVital.measured_at)).first()

        spo2 = db.query(HealthVital).filter(
            HealthVital.elderly_id == elderly.id,
            HealthVital.metric_type == "spo2"
        ).order_by(desc(HealthVital.measured_at)).first()

        temp = db.query(HealthVital).filter(
            HealthVital.elderly_id == elderly.id,
            HealthVital.metric_type == "temperature"
        ).order_by(desc(HealthVital.measured_at)).first()

        device = db.query(WearableDevice).filter(
            WearableDevice.elderly_id == elderly.id
        ).first()

        risk = db.query(RiskAssessment).filter(
            RiskAssessment.elderly_id == elderly.id
        ).order_by(desc(RiskAssessment.calculated_at)).first()

        elderly_cards.append({
            "id": elderly.id,
            "name": elderly.user.full_name if elderly.user else "Elderly Patient",
            "age": elderly.age,
            "relationship": profile.relationship_to_elder or "Family",
            "avatar_url": elderly.avatar_url,
            "linking_code": elderly.linking_code,
            "vitals_status": hr.status if hr else "normal",
            "heart_rate": f"{hr.value} BPM" if hr else "--",
            "spo2": f"{spo2.value}%" if spo2 else "--",
            "temperature": f"{temp.value}°C" if temp else "--",
            "risk_level": risk.risk_level if risk else "low",
            "wearable_connected": device.connection_status == "connected" if device else False,
            "battery_level": device.battery_level if device else 0,
        })

        # Check any active emergency
        recent_emergencies = db.query(EmergencyIncident).filter(
            EmergencyIncident.elderly_id == elderly.id,
            EmergencyIncident.status.in_(["active_countdown", "dispatched"])
        ).all()
        for inc in recent_emergencies:
            active_incidents.append({
                "incident_id": inc.id,
                "patient_name": elderly.user.full_name if elderly.user else "Patient",
                "title": inc.title,
                "severity": inc.severity,
                "location": inc.location_text,
                "triggered_at": inc.triggered_at.isoformat(),
            })

    return {
        "caregiver_name": current_user.full_name,
        "relationship": profile.relationship_to_elder,
        "linked_elders": elderly_cards,
        "active_alerts": active_incidents,
    }

@router.post("/link-by-code")
def link_elderly_by_code(
    data: LinkElderlyRequest,
    current_user: User = Depends(require_role(["caregiver"])),
    db: Session = Depends(get_db)
):
    profile = current_user.caregiver_profile
    if not profile:
        raise HTTPException(status_code=404, detail="Caregiver profile not found")

    elderly = db.query(ElderlyProfile).filter(
        ElderlyProfile.linking_code == data.linking_code.strip()
    ).first()
    if not elderly:
        raise HTTPException(status_code=404, detail="Invalid linking code. Elderly profile not found.")

    # Check if already linked
    existing = db.query(CaregiverElderlyLink).filter(
        CaregiverElderlyLink.caregiver_id == profile.id,
        CaregiverElderlyLink.elderly_id == elderly.id
    ).first()
    if existing:
        return {"status": "success", "message": "Already linked to this profile"}

    link = CaregiverElderlyLink(
        id=str(uuid.uuid4()),
        caregiver_id=profile.id,
        elderly_id=elderly.id,
        status="active",
    )
    db.add(link)
    db.commit()

    return {
        "status": "success",
        "message": f"Successfully linked to {elderly.user.full_name if elderly.user else 'Elderly'}",
        "elderly_id": elderly.id,
    }
