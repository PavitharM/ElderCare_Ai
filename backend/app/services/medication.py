"""Medication schedules, dose logs and adherence (FR-14..FR-18).

Dose logs are materialised lazily: whenever a schedule is read, today's logs are created as
"pending" and any pending dose older than MEDICATION_MISSED_GRACE_MINUTES becomes "missed".
"""

from datetime import date, datetime, time, timedelta
from typing import Dict, List, Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

from ..core.config import settings
from ..core.time import LOCAL_TZ, local_now, local_today, utcnow
from ..models.medication import Medication, MedicationLog
from ..schemas.medication import MedicationCreate, MedicationItemOut, MedicationUpdate

VALID_STATUSES = ("taken", "missed", "pending", "skipped")


def _parse_time(value: str) -> time:
    h, m = value.split(":")[:2]
    return time(int(h), int(m))


def _active_meds(db: Session, elderly_id: str) -> List[Medication]:
    return db.query(Medication).filter(Medication.elderly_id == elderly_id, Medication.is_active.is_(True)).all()


def sync_logs(db: Session, elderly_id: str) -> None:
    today = local_today()
    meds = _active_meds(db, elderly_id)
    existing = {
        (l.medication_id, l.scheduled_time)
        for l in db.query(MedicationLog).filter(
            MedicationLog.elderly_id == elderly_id, MedicationLog.scheduled_date == today
        )
    }
    for med in meds:
        if med.is_due_on(today.weekday()) and (med.id, med.scheduled_time) not in existing:
            db.add(
                MedicationLog(
                    medication_id=med.id,
                    elderly_id=elderly_id,
                    scheduled_date=today,
                    scheduled_time=med.scheduled_time,
                    status="pending",
                )
            )

    cutoff = local_now() - timedelta(minutes=settings.MEDICATION_MISSED_GRACE_MINUTES)
    pending = db.query(MedicationLog).filter(
        MedicationLog.elderly_id == elderly_id,
        MedicationLog.status == "pending",
        MedicationLog.scheduled_date <= today,
    )
    for log in pending:
        due = datetime.combine(log.scheduled_date, log.scheduled_time, tzinfo=LOCAL_TZ)
        if due < cutoff:
            log.status = "missed"
    db.commit()


def _to_item(med: Medication, log: Optional[MedicationLog]) -> MedicationItemOut:
    status = log.status if log else "pending"
    return MedicationItemOut(
        id=med.id,
        name=med.name,
        dosage=med.dosage,
        schedule_period=med.schedule_period,
        time=med.scheduled_time.strftime("%I:%M %p"),
        instruction=med.instruction,
        is_taken=status == "taken",
        status=status,
        frequency=med.frequency,
    )


def todays_schedule(db: Session, elderly_id: str) -> List[MedicationItemOut]:
    sync_logs(db, elderly_id)
    today = local_today()
    logs = {
        l.medication_id: l
        for l in db.query(MedicationLog).filter(
            MedicationLog.elderly_id == elderly_id, MedicationLog.scheduled_date == today
        )
    }
    meds = sorted(_active_meds(db, elderly_id), key=lambda m: m.scheduled_time)
    return [_to_item(m, logs.get(m.id)) for m in meds if m.is_due_on(today.weekday())]


def next_pending(db: Session, elderly_id: str) -> Optional[MedicationLog]:
    sync_logs(db, elderly_id)
    return (
        db.query(MedicationLog)
        .filter(
            MedicationLog.elderly_id == elderly_id,
            MedicationLog.scheduled_date == local_today(),
            MedicationLog.status == "pending",
        )
        .order_by(MedicationLog.scheduled_time)
        .first()
    )


def get_medication(db: Session, medication_id: str) -> Medication:
    med = db.get(Medication, medication_id)
    if not med:
        raise HTTPException(status_code=404, detail="Medication not found")
    return med


def set_dose_status(db: Session, med: Medication, status: str) -> MedicationLog:
    if status not in VALID_STATUSES:
        raise HTTPException(status_code=422, detail=f"status must be one of {VALID_STATUSES}")
    today = local_today()
    log = (
        db.query(MedicationLog)
        .filter(
            MedicationLog.medication_id == med.id,
            MedicationLog.scheduled_date == today,
            MedicationLog.scheduled_time == med.scheduled_time,
        )
        .first()
    )
    if not log:
        log = MedicationLog(
            medication_id=med.id,
            elderly_id=med.elderly_id,
            scheduled_date=today,
            scheduled_time=med.scheduled_time,
        )
        db.add(log)
    log.status = status
    log.confirmed_at = utcnow() if status in ("taken", "missed", "skipped") else None
    db.commit()
    return log


def create(db: Session, elderly_id: str, data: MedicationCreate) -> Medication:
    if data.frequency == "weekly" and not data.days_of_week:
        raise HTTPException(status_code=422, detail="days_of_week is required for weekly medications")
    med = Medication(
        elderly_id=elderly_id,
        name=data.name,
        dosage=data.dosage,
        schedule_period=data.schedule_period,
        scheduled_time=_parse_time(data.scheduled_time),
        frequency=data.frequency,
        days_of_week=data.days_of_week if data.frequency == "weekly" else None,
        instruction=data.instruction,
        is_active=True,
    )
    db.add(med)
    db.commit()
    db.refresh(med)
    return med


def update(db: Session, med: Medication, data: MedicationUpdate) -> Medication:
    changes = data.model_dump(exclude_unset=True)
    if "scheduled_time" in changes:
        changes["scheduled_time"] = _parse_time(changes["scheduled_time"])
    for key, value in changes.items():
        setattr(med, key, value)
    if med.frequency == "weekly" and not med.days_of_week:
        raise HTTPException(status_code=422, detail="days_of_week is required for weekly medications")
    db.commit()
    db.refresh(med)
    return med


def to_item(db: Session, med: Medication) -> MedicationItemOut:
    log = (
        db.query(MedicationLog)
        .filter(MedicationLog.medication_id == med.id, MedicationLog.scheduled_date == local_today())
        .first()
    )
    return _to_item(med, log)


# ---------- Adherence (FR-17, FR-18) ----------

def adherence_counts(db: Session, elderly_id: str, days: int = 7) -> Dict[str, int]:
    """Counts only doses whose outcome is known (taken/missed/skipped); pending doses are excluded."""
    since = local_today() - timedelta(days=days - 1)
    logs = db.query(MedicationLog).filter(
        MedicationLog.elderly_id == elderly_id,
        MedicationLog.scheduled_date >= since,
        MedicationLog.status != "pending",
    ).all()
    taken = sum(1 for l in logs if l.status == "taken")
    missed = sum(1 for l in logs if l.status in ("missed", "skipped"))
    return {"taken": taken, "missed": missed, "total": taken + missed}


def streak_days(db: Session, elderly_id: str, max_days: int = 365) -> int:
    """Consecutive past days (ending yesterday, or today if complete) on which every dose was taken."""
    since = local_today() - timedelta(days=max_days)
    by_day: Dict[date, List[str]] = {}
    for l in db.query(MedicationLog).filter(
        MedicationLog.elderly_id == elderly_id, MedicationLog.scheduled_date >= since
    ):
        by_day.setdefault(l.scheduled_date, []).append(l.status)

    today = local_today()
    day = today if by_day.get(today) and all(s == "taken" for s in by_day[today]) else today - timedelta(days=1)
    streak = 0
    while day in by_day and all(s == "taken" for s in by_day[day]):
        streak += 1
        day -= timedelta(days=1)
    return streak


def adherence_summary(db: Session, elderly_id: str) -> dict:
    sync_logs(db, elderly_id)
    counts = adherence_counts(db, elderly_id, days=7)
    pct = int(round(counts["taken"] / counts["total"] * 100)) if counts["total"] else 0
    return {
        "adherence_percentage": pct,
        "streak_days": streak_days(db, elderly_id),
        "taken_doses_this_week": counts["taken"],
        "total_doses_this_week": counts["total"],
        "missed_doses_this_week": counts["missed"],
    }
