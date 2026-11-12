from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ....core.constants import RISK_NORMAL
from ....core.time import as_utc
from ....db.session import get_db
from ....models.emergency import EmergencyIncident
from ....models.user import User
from ....models.vitals import WearableDevice
from ....schemas.caregiver import LinkElderlyRequest
from ....services import accounts, emergency, risk, vitals
from ...deps import require_role

router = APIRouter()


def _fmt(v, unit: str) -> str:
    return f"{float(v.value):g}{unit}" if v else "--"


@router.get("/portal")
def get_caregiver_portal(current_user: User = Depends(require_role("caregiver")), db: Session = Depends(get_db)):
    profile = current_user.caregiver_profile
    links = [l for l in profile.elderly_links if l.status == "active"]
    emergency.escalate_due(db, [l.elderly_id for l in links])

    cards, alerts = [], []
    for link in links:
        elderly = link.elderly
        hr = vitals.latest(db, elderly.id, "heart_rate")
        spo2 = vitals.latest(db, elderly.id, "spo2")
        temp = vitals.latest(db, elderly.id, "temperature")
        device = db.query(WearableDevice).filter(WearableDevice.elderly_id == elderly.id).first()
        assessment = risk.latest(db, elderly.id)
        statuses = [v.status for v in (hr, spo2, temp) if v]
        worst = next((s for s in ("critical", "warning", "normal", "optimal") if s in statuses), "normal")

        cards.append({
            "id": elderly.id,
            "name": elderly.user.full_name,
            "age": elderly.age,
            "relationship": profile.relationship_to_elder or "Family",
            "avatar_url": elderly.avatar_url,
            "linking_code": elderly.linking_code,
            "vitals_status": worst,
            "heart_rate": _fmt(hr, " BPM"),
            "spo2": _fmt(spo2, "%"),
            "temperature": _fmt(temp, "°C"),
            "vitals_stale": vitals.is_stale(hr),
            "risk_level": assessment.risk_level if assessment else RISK_NORMAL,
            "wearable_connected": bool(device and device.connection_status == "connected"),
            "battery_level": device.battery_level if device else None,
        })

        active = (
            db.query(EmergencyIncident)
            .filter(EmergencyIncident.elderly_id == elderly.id, EmergencyIncident.status.in_(emergency.ACTIVE_STATUSES))
            .all()
        )
        for inc in active:
            alerts.append({
                "incident_id": inc.id,
                "elderly_id": elderly.id,
                "patient_name": elderly.user.full_name,
                "title": inc.title,
                "severity": inc.severity,
                "status": inc.status,
                "location": inc.location_text,
                "triggered_at": as_utc(inc.triggered_at).isoformat(),
            })

    return {
        "caregiver_name": current_user.full_name,
        "relationship": profile.relationship_to_elder,
        "linked_elders": cards,
        "active_alerts": alerts,
    }


@router.post("/link-by-code")
def link_elderly_by_code(
    data: LinkElderlyRequest,
    current_user: User = Depends(require_role("caregiver")),
    db: Session = Depends(get_db),
):
    elderly = accounts.find_by_linking_code(db, data.linking_code)
    created = accounts.link_caregiver(db, current_user.caregiver_profile, elderly)
    return {
        "status": "success",
        "message": f"Linked to {elderly.user.full_name}" if created else "Already linked to this profile",
        "elderly_id": elderly.id,
    }
