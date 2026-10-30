import secrets
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from ...core.database import get_db
from ...models.user import User
from ...models.elderly import ElderlyProfile, EmergencyContact, HospitalQRToken
from ...models.vitals import HealthVital
from ...schemas.elderly import TriageSummaryOut, EmergencyContactOut
from ..deps import get_current_user

router = APIRouter()

@router.post("/generate-token")
def generate_triage_token(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not current_user.elderly_profile:
        raise HTTPException(status_code=400, detail="Only elderly profiles can generate triage QR tokens")

    # Generate secure 32-byte hex token (64 chars)
    token_str = f"EG-EMERGENCY-{secrets.token_hex(20).upper()}"
    now = datetime.now(timezone.utc)
    qr_token = HospitalQRToken(
        elderly_id=current_user.elderly_profile.id,
        token=token_str,
        expires_at=now + timedelta(hours=24),
        is_revoked=False,
        access_count=0,
    )
    db.add(qr_token)
    db.commit()

    return {
        "status": "success",
        "qr_token": token_str,
        "expires_at": qr_token.expires_at.isoformat(),
        "instruction": "This QR token grants emergency medical personnel 24-hour access to vital triage data.",
    }

@router.get("/summary/{token}", response_model=TriageSummaryOut)
def get_triage_summary(token: str, db: Session = Depends(get_db)):
    qr_record = db.query(HospitalQRToken).filter(
        HospitalQRToken.token == token.strip()
    ).first()

    if not qr_record:
        raise HTTPException(status_code=404, detail="Invalid emergency token.")
    if qr_record.is_revoked:
        raise HTTPException(status_code=403, detail="Emergency token has been revoked by patient.")
    if datetime.now(timezone.utc) > qr_record.expires_at.replace(tzinfo=timezone.utc):
        raise HTTPException(status_code=410, detail="Emergency token has expired.")

    # Increment audit access count
    qr_record.access_count += 1
    db.commit()

    elderly = qr_record.elderly
    if not elderly:
        raise HTTPException(status_code=404, detail="Patient profile not found.")

    contacts = db.query(EmergencyContact).filter(
        EmergencyContact.elderly_id == elderly.id
    ).order_by(EmergencyContact.priority_order).all()

    # Latest vitals
    vitals = {}
    for metric in ["heart_rate", "spo2", "temperature"]:
        v = db.query(HealthVital).filter(
            HealthVital.elderly_id == elderly.id,
            HealthVital.metric_type == metric
        ).order_by(desc(HealthVital.measured_at)).first()
        if v:
            vitals[metric] = f"{v.value} {v.unit} ({v.status})"

    return TriageSummaryOut(
        patient_name=elderly.user.full_name if elderly.user else "Patient",
        age=elderly.age,
        gender=elderly.gender,
        blood_group=elderly.blood_group,
        allergies=elderly.allergies or [],
        chronic_conditions=elderly.chronic_conditions or [],
        primary_doctor=elderly.primary_doctor,
        emergency_contacts=[EmergencyContactOut.model_validate(c) for c in contacts],
        latest_vitals=vitals,
        generated_at=datetime.now(timezone.utc),
    )
