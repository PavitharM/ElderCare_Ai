"""Gathers patient data, runs the risk engine and triggers the emergency workflow on Critical (FR-12, FR-13, FR-21)."""

from datetime import timedelta
from typing import Optional

from sqlalchemy import desc
from sqlalchemy.orm import Session

from ..ai.risk_engine import FallEvent, LatestVital, RiskInputs, assess
from ..core.config import settings
from ..core.constants import DISCLAIMER, RISK_CRITICAL, VITAL_METRICS
from ..core.time import as_utc, utcnow
from ..models.emergency import EmergencyIncident
from ..models.risk import RiskAssessment
from . import emergency, medication, vitals


def _inputs(db: Session, elderly_id: str) -> RiskInputs:
    baseline, _ = vitals.get_baseline(db, elderly_id)
    now = utcnow()
    since_7d = now - timedelta(days=7)

    latest, history = {}, {}
    for metric in VITAL_METRICS:
        records = vitals.values_since(db, elderly_id, metric, since_7d)
        last = vitals.latest(db, elderly_id, metric)
        if last:
            latest[metric] = LatestVital(float(last.value), last.unit, vitals.age_minutes(last))
        history[metric] = [float(r.value) for r in records if not last or r.id != last.id]

    activity = vitals.values_since(db, elderly_id, "activity_level", now - timedelta(minutes=10))

    falls = (
        db.query(EmergencyIncident)
        .filter(
            EmergencyIncident.elderly_id == elderly_id,
            EmergencyIncident.incident_type == "fall_detected",
            EmergencyIncident.triggered_at >= since_7d,
        )
        .all()
    )
    fall_events = [
        FallEvent(
            age_minutes=(now - as_utc(f.triggered_at)).total_seconds() / 60.0,
            # A fall still inside its countdown is not yet confirmed
            cancelled=f.status in ("false_alarm", "active_countdown"),
        )
        for f in falls
    ]

    stats = medication.adherence_counts(db, elderly_id, days=7)
    return RiskInputs(
        baseline=baseline,
        latest=latest,
        history=history,
        stale_after_minutes=settings.VITAL_STALE_AFTER_MINUTES,
        doses_taken=stats["taken"],
        doses_total=stats["total"],
        falls_7d=fall_events,
        active_sos=emergency.has_active_sos(db, elderly_id),
        recent_activity_mg=[float(a.value) for a in activity],
    )


def evaluate(db: Session, elderly_id: str) -> tuple[RiskAssessment, Optional[EmergencyIncident]]:
    """Compute and store a new assessment. A Critical result raises a critical-vital incident
    (which alerts caregivers) unless an SOS or fall incident already covers it."""
    result = assess(_inputs(db, elderly_id))
    assessment = RiskAssessment(
        elderly_id=elderly_id,
        risk_level=result.risk_level,
        status_label=result.status_label,
        confidence_score=result.confidence_score,
        vital_score=result.vital_score,
        adherence_score=result.adherence_score,
        fall_risk_score=result.fall_risk_score,
        contributing_factors=result.contributing_factors,
        anomalies=result.anomalies,
        disclaimer=DISCLAIMER,
        calculated_at=utcnow(),
    )
    db.add(assessment)

    incident = None
    if result.risk_level == RISK_CRITICAL and not _has_active_emergency(db, elderly_id):
        incident = emergency.create_critical_vital(db, elderly_id, result.contributing_factors)
    db.flush()
    return assessment, incident


def _has_active_emergency(db: Session, elderly_id: str) -> bool:
    return (
        db.query(EmergencyIncident.id)
        .filter(
            EmergencyIncident.elderly_id == elderly_id,
            EmergencyIncident.status.in_(emergency.ACTIVE_STATUSES),
        )
        .first()
        is not None
    )


def latest(db: Session, elderly_id: str) -> Optional[RiskAssessment]:
    return (
        db.query(RiskAssessment)
        .filter(RiskAssessment.elderly_id == elderly_id)
        .order_by(desc(RiskAssessment.calculated_at))
        .first()
    )


def latest_or_evaluate(db: Session, elderly_id: str) -> RiskAssessment:
    assessment = latest(db, elderly_id)
    if assessment is None:
        assessment, _ = evaluate(db, elderly_id)
        db.commit()
        db.refresh(assessment)
    return assessment
