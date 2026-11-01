"""Tokenized hospital QR access (FR-04, FR-23, FR-24). One active token per patient."""

import secrets
from datetime import timedelta

from fastapi import HTTPException
from sqlalchemy.orm import Session

from ..core.config import settings
from ..core.constants import VITAL_METRICS
from ..core.time import as_utc, utcnow
from ..models.elderly import ElderlyProfile, EmergencyContact, HospitalQRToken
from ..models.medication import Medication
from ..schemas.elderly import EmergencyContactOut, TriageSummaryOut, TriageVital
from . import risk, vitals


class TokenError(Exception):
    def __init__(self, status_code: int, message: str):
        self.status_code = status_code
        self.message = message


def qr_url(token: str) -> str:
    return f"{settings.PUBLIC_BASE_URL.rstrip('/')}/qr/{token}"


def revoke_all(db: Session, elderly_id: str) -> int:
    count = (
        db.query(HospitalQRToken)
        .filter(HospitalQRToken.elderly_id == elderly_id, HospitalQRToken.is_revoked.is_(False))
        .update({HospitalQRToken.is_revoked: True}, synchronize_session=False)
    )
    db.commit()
    return count


def generate(db: Session, elderly: ElderlyProfile) -> HospitalQRToken:
    revoke_all(db, elderly.id)
    token = HospitalQRToken(
        elderly_id=elderly.id,
        token=secrets.token_urlsafe(32),  # 43 chars, 256-bit
        expires_at=utcnow() + timedelta(hours=settings.QR_TOKEN_TTL_HOURS),
        is_revoked=False,
        access_count=0,
    )
    db.add(token)
    db.commit()
    db.refresh(token)
    return token


def validate(db: Session, token: str) -> HospitalQRToken:
    record = db.query(HospitalQRToken).filter(HospitalQRToken.token == token.strip()).first()
    if not record:
        raise TokenError(404, "This QR code is not valid.")
    if record.is_revoked:
        raise TokenError(403, "This QR code was replaced or revoked by the patient.")
    if utcnow() > as_utc(record.expires_at):
        raise TokenError(410, "This QR code has expired. Ask the patient to generate a new one.")
    return record


def summary(db: Session, token: str) -> TriageSummaryOut:
    """Read-only summary limited to clinically necessary fields (SRS 5.4). Each access is audited."""
    record = validate(db, token)
    record.access_count = (record.access_count or 0) + 1
    record.last_accessed_at = utcnow()
    db.commit()

    elderly = record.elderly
    contacts = (
        db.query(EmergencyContact)
        .filter(EmergencyContact.elderly_id == elderly.id)
        .order_by(EmergencyContact.priority_order)
        .all()
    )
    latest_vitals = {}
    for metric in VITAL_METRICS:
        v = vitals.latest(db, elderly.id, metric)
        if v:
            latest_vitals[metric] = TriageVital(
                value=float(v.value), unit=v.unit, status=v.status, measured_at=as_utc(v.measured_at)
            )
    assessment = risk.latest(db, elderly.id)
    meds = (
        db.query(Medication)
        .filter(Medication.elderly_id == elderly.id, Medication.is_active.is_(True))
        .order_by(Medication.scheduled_time)
        .all()
    )

    return TriageSummaryOut(
        patient_name=elderly.user.full_name if elderly.user else "Patient",
        age=elderly.age,
        gender=elderly.gender,
        blood_group=elderly.blood_group,
        allergies=elderly.allergies or [],
        chronic_conditions=elderly.chronic_conditions or [],
        primary_doctor=elderly.primary_doctor,
        emergency_contacts=[EmergencyContactOut.model_validate(c) for c in contacts],
        latest_vitals=latest_vitals,
        vitals_24h=vitals.summary_24h(db, elderly.id),
        risk_level=assessment.risk_level if assessment else None,
        risk_label=assessment.status_label if assessment else None,
        active_medications=[f"{m.name} - {m.dosage} ({m.scheduled_time.strftime('%I:%M %p')})" for m in meds],
        generated_at=utcnow(),
        expires_at=as_utc(record.expires_at),
    )


def raise_http(err: TokenError) -> HTTPException:
    return HTTPException(status_code=err.status_code, detail=err.message)
