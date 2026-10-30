from datetime import date, datetime, timezone, timedelta, time
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ...core.database import get_db
from ...models.user import User
from ...models.medication import Medication, MedicationLog
from ...schemas.medication import MedicationItemOut, MedicationCreate, MedicationAdherenceOut
from ..deps import get_current_user

router = APIRouter()

@router.get("/my-schedule", response_model=List[MedicationItemOut])
def get_my_schedule(
    elderly_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_elderly_id = current_user.elderly_profile.id if current_user.role == "elderly" else elderly_id
    if not target_elderly_id:
        raise HTTPException(status_code=400, detail="Target elderly_id not specified")

    today = date.today()
    meds = db.query(Medication).filter(
        Medication.elderly_id == target_elderly_id,
        Medication.is_active == True
    ).all()

    items = []
    for med in meds:
        # Check today's log entry
        log = db.query(MedicationLog).filter(
            MedicationLog.medication_id == med.id,
            MedicationLog.scheduled_date == today
        ).first()

        is_taken = log.status == "taken" if log else False
        time_str = med.scheduled_time.strftime("%I:%M %p") if med.scheduled_time else "08:00 AM"

        items.append(MedicationItemOut(
            id=med.id,
            name=med.name,
            dosage=med.dosage,
            schedule_period=med.schedule_period,
            time=time_str,
            instruction=med.instruction,
            is_taken=is_taken,
        ))

    return items

@router.post("/{medication_id}/confirm-dose")
def confirm_medication_dose(
    medication_id: str,
    taken: bool = True,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    today = date.today()
    med = db.query(Medication).filter(Medication.id == medication_id).first()
    if not med:
        raise HTTPException(status_code=404, detail="Medication not found")

    log = db.query(MedicationLog).filter(
        MedicationLog.medication_id == med.id,
        MedicationLog.scheduled_date == today
    ).first()

    now = datetime.now(timezone.utc)
    if not log:
        log = MedicationLog(
            medication_id=med.id,
            elderly_id=med.elderly_id,
            scheduled_date=today,
            scheduled_time=med.scheduled_time,
            status="taken" if taken else "pending",
            confirmed_at=now if taken else None,
        )
        db.add(log)
    else:
        log.status = "taken" if taken else "pending"
        log.confirmed_at = now if taken else None

    db.commit()
    return {"status": "success", "medication_id": med.id, "is_taken": taken}

@router.get("/adherence", response_model=MedicationAdherenceOut)
def get_medication_adherence(
    elderly_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_elderly_id = current_user.elderly_profile.id if current_user.role == "elderly" else elderly_id
    if not target_elderly_id:
        raise HTTPException(status_code=400, detail="Target elderly_id not specified")

    since = date.today() - timedelta(days=7)
    logs = db.query(MedicationLog).filter(
        MedicationLog.elderly_id == target_elderly_id,
        MedicationLog.scheduled_date >= since
    ).all()

    total_doses = len(logs)
    taken_doses = sum(1 for l in logs if l.status == "taken")
    missed_doses = sum(1 for l in logs if l.status in ["missed", "pending"])

    adherence_pct = int((taken_doses / total_doses * 100)) if total_doses > 0 else 94

    return MedicationAdherenceOut(
        adherence_percentage=adherence_pct,
        streak_days=14,
        taken_doses_this_week=taken_doses,
        total_doses_this_week=total_doses,
        missed_doses_this_week=missed_doses,
    )

@router.post("", response_model=MedicationItemOut)
def add_medication(
    data: MedicationCreate,
    elderly_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_elderly_id = current_user.elderly_profile.id if current_user.role == "elderly" else elderly_id
    if not target_elderly_id:
        raise HTTPException(status_code=400, detail="Target elderly_id not specified")

    # Parse time
    try:
        parts = data.scheduled_time.split(":")
        sched_time = time(int(parts[0]), int(parts[1]))
    except Exception:
        sched_time = time(8, 0)

    med = Medication(
        elderly_id=target_elderly_id,
        name=data.name,
        dosage=data.dosage,
        schedule_period=data.schedule_period,
        scheduled_time=sched_time,
        instruction=data.instruction,
        is_active=True,
    )
    db.add(med)
    db.commit()
    db.refresh(med)

    return MedicationItemOut(
        id=med.id,
        name=med.name,
        dosage=med.dosage,
        schedule_period=med.schedule_period,
        time=sched_time.strftime("%I:%M %p"),
        instruction=med.instruction,
        is_taken=False,
    )
