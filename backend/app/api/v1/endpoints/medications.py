from typing import List, Literal, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ....db.session import get_db
from ....models.elderly import ElderlyProfile
from ....models.user import User
from ....schemas.medication import MedicationAdherenceOut, MedicationCreate, MedicationItemOut, MedicationUpdate
from ....services import access, medication
from ...deps import get_current_user, target_elderly

router = APIRouter()


@router.get("/my-schedule", response_model=List[MedicationItemOut])
def get_my_schedule(elderly: ElderlyProfile = Depends(target_elderly()), db: Session = Depends(get_db)):
    """Today's doses with Taken / Missed / Pending status."""
    return medication.todays_schedule(db, elderly.id)


@router.post("/{medication_id}/confirm-dose")
def confirm_medication_dose(
    medication_id: str,
    taken: bool = True,
    status: Optional[Literal["taken", "missed", "pending", "skipped"]] = Query(
        None, description="Overrides `taken` when given (FR-17)"
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    med = medication.get_medication(db, medication_id)
    access.ensure_can_access(db, current_user, med.elderly_id, None if current_user.role == "elderly" else "can_manage_meds")
    final_status = status or ("taken" if taken else "pending")
    log = medication.set_dose_status(db, med, final_status)
    return {"status": "success", "medication_id": med.id, "is_taken": log.status == "taken", "dose_status": log.status}


@router.get("/adherence", response_model=MedicationAdherenceOut)
def get_medication_adherence(elderly: ElderlyProfile = Depends(target_elderly()), db: Session = Depends(get_db)):
    return medication.adherence_summary(db, elderly.id)


@router.post("", response_model=MedicationItemOut, status_code=201)
def add_medication(
    data: MedicationCreate,
    elderly: ElderlyProfile = Depends(target_elderly("can_manage_meds")),
    db: Session = Depends(get_db),
):
    med = medication.create(db, elderly.id, data)
    return medication.to_item(db, med)


@router.put("/{medication_id}", response_model=MedicationItemOut)
def update_medication(
    medication_id: str,
    data: MedicationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    med = medication.get_medication(db, medication_id)
    access.ensure_can_access(db, current_user, med.elderly_id, None if current_user.role == "elderly" else "can_manage_meds")
    return medication.to_item(db, medication.update(db, med, data))


@router.delete("/{medication_id}", status_code=204)
def deactivate_medication(
    medication_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Soft delete: history and adherence records are kept (NFR-09)."""
    med = medication.get_medication(db, medication_id)
    access.ensure_can_access(db, current_user, med.elderly_id, None if current_user.role == "elderly" else "can_manage_meds")
    med.is_active = False
    db.commit()
