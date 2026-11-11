"""Emergency incidents: falls (with confirmation window), manual SOS and critical vitals (FR-14, FR-19)."""

from datetime import timedelta
from typing import Iterable, Optional

from fastapi import HTTPException
from sqlalchemy import desc
from sqlalchemy.orm import Session

from ..core.config import settings
from ..core.time import as_utc, utcnow
from ..models.elderly import ElderlyProfile
from ..models.emergency import EmergencyIncident
from ..models.user import User
from . import access
from .notifications import notify_caregivers

ACTIVE_STATUSES = ("active_countdown", "dispatched")


def _dispatch(db: Session, incident: EmergencyIncident) -> None:
    incident.status = "dispatched"
    incident.escalate_at = None
    db.flush()
    notify_caregivers(db, incident)


def create_fall(
    db: Session,
    elderly: ElderlyProfile,
    *,
    impact_g: Optional[float],
    title: str = "Potential Fall Detected",
    description: Optional[str] = None,
    location_text: str = "Home",
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
) -> EmergencyIncident:
    """A fall waits FALL_CONFIRM_SECONDS for the user to cancel before caregivers are alerted.
    A second fall packet during an open countdown reuses the same incident."""
    open_fall = (
        db.query(EmergencyIncident)
        .filter(
            EmergencyIncident.elderly_id == elderly.id,
            EmergencyIncident.incident_type == "fall_detected",
            EmergencyIncident.status == "active_countdown",
        )
        .first()
    )
    if open_fall:
        return open_fall

    now = utcnow()
    incident = EmergencyIncident(
        elderly_id=elderly.id,
        incident_type="fall_detected",
        title=title,
        description=description or (f"Impact of {impact_g:.1f}G registered by the wearable." if impact_g else None),
        impact_force_g=impact_g,
        location_text=location_text,
        latitude=latitude,
        longitude=longitude,
        severity="critical",
        status="active_countdown",
        triggered_at=now,
        escalate_at=now + timedelta(seconds=settings.FALL_CONFIRM_SECONDS),
    )
    db.add(incident)
    db.flush()
    return incident


def create_sos(
    db: Session,
    elderly: ElderlyProfile,
    location_text: str = "Home",
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
) -> EmergencyIncident:
    incident = EmergencyIncident(
        elderly_id=elderly.id,
        incident_type="manual_sos",
        title="Manual SOS Triggered",
        description="The elderly user requested emergency help from the app.",
        location_text=location_text,
        latitude=latitude,
        longitude=longitude,
        severity="critical",
        triggered_at=utcnow(),
    )
    db.add(incident)
    _dispatch(db, incident)
    return incident


def create_critical_vital(db: Session, elderly_id: str, factors: Iterable[str]) -> Optional[EmergencyIncident]:
    """Raise one critical-vital incident at a time; skip if one is already active."""
    existing = (
        db.query(EmergencyIncident)
        .filter(
            EmergencyIncident.elderly_id == elderly_id,
            EmergencyIncident.incident_type == "critical_vital",
            EmergencyIncident.status.in_(ACTIVE_STATUSES),
        )
        .first()
    )
    if existing:
        return None
    incident = EmergencyIncident(
        elderly_id=elderly_id,
        incident_type="critical_vital",
        title="Critical Health Condition",
        description="; ".join(list(factors)[:3]) or "Risk engine classified the condition as Critical.",
        severity="critical",
        triggered_at=utcnow(),
    )
    db.add(incident)
    _dispatch(db, incident)
    return incident


def escalate(db: Session, incident: EmergencyIncident) -> EmergencyIncident:
    if incident.status == "active_countdown":
        _dispatch(db, incident)
    return incident


def escalate_due(db: Session, elderly_ids: Optional[list[str]] = None) -> None:
    """Escalate fall countdowns whose confirmation window expired (e.g. phone went offline)."""
    q = db.query(EmergencyIncident).filter(
        EmergencyIncident.status == "active_countdown",
        EmergencyIncident.escalate_at.isnot(None),
    )
    if elderly_ids is not None:
        q = q.filter(EmergencyIncident.elderly_id.in_(elderly_ids))
    now = utcnow()
    due = [i for i in q.all() if as_utc(i.escalate_at) <= now]
    for incident in due:
        _dispatch(db, incident)
    if due:
        db.commit()


def cancel(db: Session, incident: EmergencyIncident) -> EmergencyIncident:
    if incident.status in ("resolved", "false_alarm"):
        return incident
    incident.status = "false_alarm"
    incident.escalate_at = None
    incident.resolved_at = utcnow()
    return incident


def resolve(db: Session, incident: EmergencyIncident) -> EmergencyIncident:
    if incident.status in ACTIVE_STATUSES:
        incident.status = "resolved"
        incident.escalate_at = None
        incident.resolved_at = utcnow()
    return incident


def get_for_user(db: Session, user: User, incident_id: str) -> EmergencyIncident:
    incident = db.get(EmergencyIncident, incident_id)
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    access.ensure_can_access(db, user, incident.elderly_id)
    return incident


def list_for_elderly(db: Session, elderly_id: str, limit: int = 100) -> list[EmergencyIncident]:
    return (
        db.query(EmergencyIncident)
        .filter(EmergencyIncident.elderly_id == elderly_id)
        .order_by(desc(EmergencyIncident.triggered_at))
        .limit(limit)
        .all()
    )


def has_active_sos(db: Session, elderly_id: str) -> bool:
    return (
        db.query(EmergencyIncident.id)
        .filter(
            EmergencyIncident.elderly_id == elderly_id,
            EmergencyIncident.incident_type == "manual_sos",
            EmergencyIncident.status == "dispatched",
        )
        .first()
        is not None
    )
//emergency end