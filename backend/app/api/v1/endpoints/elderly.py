from fastapi import APIRouter, Depends
from sqlalchemy import desc
from sqlalchemy.orm import Session

from ....core.constants import DISCLAIMER, RISK_LABELS, RISK_NORMAL
from ....core.time import as_utc
from ....db.session import get_db
from ....models.elderly import ElderlyProfile, EmergencyContact
from ....models.emergency import EmergencyIncident
from ....models.medication import MedicationLog
from ....models.vitals import WearableDevice
from ....schemas.elderly import ElderlyProfileOut, ElderlyProfileUpdate, EmergencyContactOut
from ....services import medication, risk, vitals
from ...deps import get_current_elderly

router = APIRouter()


def _profile_out(db: Session, profile: ElderlyProfile) -> ElderlyProfileOut:
    contacts = (
        db.query(EmergencyContact)
        .filter(EmergencyContact.elderly_id == profile.id)
        .order_by(EmergencyContact.priority_order)
        .all()
    )
    return ElderlyProfileOut(
        id=profile.id,
        user_id=profile.user_id,
        name=profile.user.full_name,
        phone=profile.user.phone,
        age=profile.age,
        gender=profile.gender,
        blood_group=profile.blood_group,
        address=profile.address,
        linking_code=profile.linking_code,
        chronic_conditions=profile.chronic_conditions or [],
        allergies=profile.allergies or [],
        primary_doctor=profile.primary_doctor,
        avatar_url=profile.avatar_url,
        emergency_contacts=[EmergencyContactOut.model_validate(c) for c in contacts],
    )


@router.get("/me/profile", response_model=ElderlyProfileOut)
def get_my_profile(profile: ElderlyProfile = Depends(get_current_elderly), db: Session = Depends(get_db)):
    return _profile_out(db, profile)


@router.put("/me/profile", response_model=ElderlyProfileOut)
def update_my_profile(
    update_data: ElderlyProfileUpdate,
    profile: ElderlyProfile = Depends(get_current_elderly),
    db: Session = Depends(get_db),
):
    for key, value in update_data.model_dump(exclude_unset=True).items():
        setattr(profile, key, value)
    db.commit()
    db.refresh(profile)
    return _profile_out(db, profile)


@router.get("/me/alert-contacts")
def get_alert_contacts(profile: ElderlyProfile = Depends(get_current_elderly), db: Session = Depends(get_db)):
    """Phone numbers the patient's phone texts directly on fall / SOS / critical vitals.
    The app caches this list so SMS alerts still work without internet."""
    contacts, seen = [], set()
    for link in profile.caregiver_links:
        if link.status == "active" and link.allows("receive_alerts") and link.caregiver.user.phone not in seen:
            user = link.caregiver.user
            seen.add(user.phone)
            contacts.append({"name": user.full_name, "phone": user.phone, "relationship": "Caregiver", "source": "caregiver"})
    emergency = (
        db.query(EmergencyContact)
        .filter(EmergencyContact.elderly_id == profile.id)
        .order_by(EmergencyContact.priority_order)
        .all()
    )
    for c in emergency:
        if c.phone not in seen:
            seen.add(c.phone)
            contacts.append({"name": c.name, "phone": c.phone, "relationship": c.relationship, "source": "emergency_contact"})
    return contacts


@router.get("/me/dashboard")
def get_dashboard_summary(profile: ElderlyProfile = Depends(get_current_elderly), db: Session = Depends(get_db)):
    latest_vitals = {}
    for metric in ("heart_rate", "spo2", "temperature"):
        v = vitals.latest(db, profile.id, metric)
        if v:
            latest_vitals[metric] = {
                "value": f"{float(v.value):g}",
                "unit": v.unit,
                "status": v.status,
                "measured_at": as_utc(v.measured_at).isoformat(),
                "is_stale": vitals.is_stale(v),
            }

    device = db.query(WearableDevice).filter(WearableDevice.elderly_id == profile.id).first()
    assessment = risk.latest(db, profile.id)
    pending = medication.next_pending(db, profile.id)

    next_med = None
    if pending and pending.medication:
        next_med = {
            "id": pending.medication.id,
            "name": pending.medication.name,
            "dosage": pending.medication.dosage,
            "time": pending.scheduled_time.strftime("%I:%M %p"),
            "period": pending.medication.schedule_period,
            "instruction": pending.medication.instruction,
        }

    return {
        "patient_name": profile.user.full_name,
        "age": profile.age,
        "linking_code": profile.linking_code,
        "vitals": latest_vitals,
        "wearable": {
            "name": device.device_name if device else None,
            "connected": bool(device and device.connection_status == "connected"),
            "battery": device.battery_level if device else None,
            "last_seen": as_utc(device.last_heartbeat_at).isoformat() if device and device.last_heartbeat_at else None,
        },
        "risk_assessment": {
            "level": assessment.risk_level if assessment else RISK_NORMAL,
            "label": assessment.status_label if assessment else RISK_LABELS[RISK_NORMAL],
            "factors": assessment.contributing_factors if assessment else [],
            "disclaimer": assessment.disclaimer if assessment else DISCLAIMER,
        },
        "next_medication": next_med,
    }


@router.get("/me/history")
def get_health_history(profile: ElderlyProfile = Depends(get_current_elderly), db: Session = Depends(get_db)):
    events = []
    incidents = (
        db.query(EmergencyIncident)
        .filter(EmergencyIncident.elderly_id == profile.id)
        .order_by(desc(EmergencyIncident.triggered_at))
        .limit(20)
        .all()
    )
    for inc in incidents:
        events.append({
            "type": "emergency",
            "title": inc.title,
            "description": inc.description,
            "timestamp": as_utc(inc.triggered_at).isoformat(),
            "severity": inc.severity,
            "status": inc.status,
        })

    logs = (
        db.query(MedicationLog)
        .filter(MedicationLog.elderly_id == profile.id, MedicationLog.status.in_(["taken", "missed"]))
        .order_by(desc(MedicationLog.scheduled_date), desc(MedicationLog.scheduled_time))
        .limit(20)
        .all()
    )
    for log in logs:
        if not log.medication:
            continue
        taken = log.status == "taken"
        when = log.confirmed_at or None
        events.append({
            "type": "medication",
            "title": f"Dose {'Taken' if taken else 'Missed'}: {log.medication.name}",
            "description": f"{log.medication.dosage} scheduled {log.scheduled_time.strftime('%I:%M %p')}",
            "timestamp": as_utc(when).isoformat() if when else f"{log.scheduled_date.isoformat()}T{log.scheduled_time.isoformat()}",
            "severity": "info" if taken else "warning",
        })

    events.sort(key=lambda x: x["timestamp"], reverse=True)
    return events
