from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc
from ...core.database import get_db
from ...models.user import User
from ...models.elderly import ElderlyProfile, EmergencyContact
from ...models.vitals import HealthVital, WearableDevice
from ...models.medication import Medication, MedicationLog
from ...models.emergency import EmergencyIncident
from ...models.ai_risk import RiskAssessment
from ...schemas.elderly import ElderlyProfileOut, ElderlyProfileUpdate
from ..deps import get_current_user, require_role

router = APIRouter()

@router.get("/me/profile", response_model=ElderlyProfileOut)
def get_my_profile(
    current_user: User = Depends(require_role(["elderly"])),
    db: Session = Depends(get_db)
):
    profile = current_user.elderly_profile
    if not profile:
        raise HTTPException(status_code=404, detail="Elderly profile not found")

    contacts = db.query(EmergencyContact).filter(
        EmergencyContact.elderly_id == profile.id
    ).order_by(EmergencyContact.priority_order).all()

    return ElderlyProfileOut(
        id=profile.id,
        user_id=current_user.id,
        name=current_user.full_name,
        phone=current_user.phone,
        age=profile.age,
        gender=profile.gender,
        blood_group=profile.blood_group,
        address=profile.address,
        linking_code=profile.linking_code,
        chronic_conditions=profile.chronic_conditions or [],
        allergies=profile.allergies or [],
        primary_doctor=profile.primary_doctor,
        avatar_url=profile.avatar_url,
        emergency_contacts=contacts,
    )

@router.put("/me/profile", response_model=ElderlyProfileOut)
def update_my_profile(
    update_data: ElderlyProfileUpdate,
    current_user: User = Depends(require_role(["elderly"])),
    db: Session = Depends(get_db)
):
    profile = current_user.elderly_profile
    if not profile:
        raise HTTPException(status_code=404, detail="Elderly profile not found")

    if update_data.age is not None:
        profile.age = update_data.age
    if update_data.gender is not None:
        profile.gender = update_data.gender
    if update_data.blood_group is not None:
        profile.blood_group = update_data.blood_group
    if update_data.address is not None:
        profile.address = update_data.address
    if update_data.chronic_conditions is not None:
        profile.chronic_conditions = update_data.chronic_conditions
    if update_data.allergies is not None:
        profile.allergies = update_data.allergies
    if update_data.primary_doctor is not None:
        profile.primary_doctor = update_data.primary_doctor

    db.commit()
    db.refresh(profile)

    contacts = db.query(EmergencyContact).filter(
        EmergencyContact.elderly_id == profile.id
    ).all()

    return ElderlyProfileOut(
        id=profile.id,
        user_id=current_user.id,
        name=current_user.full_name,
        phone=current_user.phone,
        age=profile.age,
        gender=profile.gender,
        blood_group=profile.blood_group,
        address=profile.address,
        linking_code=profile.linking_code,
        chronic_conditions=profile.chronic_conditions or [],
        allergies=profile.allergies or [],
        primary_doctor=profile.primary_doctor,
        avatar_url=profile.avatar_url,
        emergency_contacts=contacts,
    )

@router.get("/me/dashboard")
def get_dashboard_summary(
    current_user: User = Depends(require_role(["elderly"])),
    db: Session = Depends(get_db)
):
    profile = current_user.elderly_profile
    if not profile:
        raise HTTPException(status_code=404, detail="Elderly profile not found")

    # Latest vitals
    vitals = {}
    for metric in ["heart_rate", "spo2", "temperature"]:
        latest = db.query(HealthVital).filter(
            HealthVital.elderly_id == profile.id,
            HealthVital.metric_type == metric
        ).order_by(desc(HealthVital.measured_at)).first()
        if latest:
            vitals[metric] = {
                "value": str(latest.value),
                "unit": latest.unit,
                "status": latest.status,
                "measured_at": latest.measured_at.isoformat(),
            }

    # Wearable device
    device = db.query(WearableDevice).filter(
        WearableDevice.elderly_id == profile.id
    ).first()

    # AI risk assessment
    risk = db.query(RiskAssessment).filter(
        RiskAssessment.elderly_id == profile.id
    ).order_by(desc(RiskAssessment.calculated_at)).first()

    # Next medication
    today = date.today()
    pending_med = db.query(MedicationLog).filter(
        MedicationLog.elderly_id == profile.id,
        MedicationLog.scheduled_date == today,
        MedicationLog.status == "pending"
    ).order_by(MedicationLog.scheduled_time).first()

    next_med_info = None
    if pending_med and pending_med.medication:
        next_med_info = {
            "id": pending_med.medication.id,
            "name": pending_med.medication.name,
            "dosage": pending_med.medication.dosage,
            "time": pending_med.scheduled_time.strftime("%I:%M %p"),
            "period": pending_med.medication.schedule_period,
            "instruction": pending_med.medication.instruction,
        }

    return {
        "patient_name": current_user.full_name,
        "age": profile.age,
        "linking_code": profile.linking_code,
        "vitals": vitals,
        "wearable": {
            "name": device.device_name if device else "ElderGuard Band",
            "connected": device.connection_status == "connected" if device else False,
            "battery": device.battery_level if device else 0,
        },
        "risk_assessment": {
            "level": risk.risk_level if risk else "low",
            "label": risk.status_label if risk else "Low Risk - Stable",
            "factors": risk.contributing_factors if risk else [],
            "disclaimer": risk.disclaimer if risk else "Algorithmic observation only.",
        },
        "next_medication": next_med_info,
    }

@router.get("/me/history")
def get_health_history(
    current_user: User = Depends(require_role(["elderly"])),
    db: Session = Depends(get_db)
):
    profile = current_user.elderly_profile
    if not profile:
        raise HTTPException(status_code=404, detail="Elderly profile not found")

    events = []

    # Emergencies
    incidents = db.query(EmergencyIncident).filter(
        EmergencyIncident.elderly_id == profile.id
    ).order_by(desc(EmergencyIncident.triggered_at)).limit(10).all()
    for inc in incidents:
        events.append({
            "type": "emergency",
            "title": inc.title,
            "description": inc.description,
            "timestamp": inc.triggered_at.isoformat(),
            "severity": inc.severity,
        })

    # Medication confirmations
    med_logs = db.query(MedicationLog).filter(
        MedicationLog.elderly_id == profile.id,
        MedicationLog.status == "taken"
    ).order_by(desc(MedicationLog.confirmed_at)).limit(10).all()
    for log in med_logs:
        if log.confirmed_at and log.medication:
            events.append({
                "type": "medication",
                "title": f"Dose Taken: {log.medication.name}",
                "description": f"{log.medication.dosage} confirmed ({log.medication.schedule_period})",
                "timestamp": log.confirmed_at.isoformat(),
                "severity": "info",
            })

    # Sort combined events descending by timestamp
    events.sort(key=lambda x: x["timestamp"], reverse=True)
    return events
