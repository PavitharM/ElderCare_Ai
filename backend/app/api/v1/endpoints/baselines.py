from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ....core.time import as_utc
from ....db.session import get_db
from ....models.elderly import ElderlyProfile, PatientBaseline
from ....models.user import User
from ....schemas.elderly import BaselineOut, BaselineUpdate
from ....services import access, vitals
from ...deps import get_current_user, target_elderly

router = APIRouter()


def _out(elderly_id: str, values: dict, row) -> BaselineOut:
    return BaselineOut(
        elderly_id=elderly_id,
        **values,
        notes=row.notes if row else None,
        defined_by=row.defined_by if row else None,
        is_default=row is None,
        updated_at=as_utc(row.updated_at) if row and row.updated_at else None,
    )


@router.get("", response_model=BaselineOut)
def get_baseline(elderly: ElderlyProfile = Depends(target_elderly()), db: Session = Depends(get_db)):
    """Personal ranges used by the risk engine; defaults apply until a doctor's values are entered."""
    values, row = vitals.get_baseline(db, elderly.id)
    return _out(elderly.id, values, row)


@router.put("", response_model=BaselineOut)
def set_baseline(
    data: BaselineUpdate,
    elderly_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Doctor-defined parameters (FR-27), entered by a linked caregiver on the doctor's behalf."""
    if current_user.role != "caregiver":
        raise HTTPException(status_code=403, detail="Only a linked caregiver can update doctor-defined ranges")
    access.ensure_can_access(db, current_user, elderly_id, "can_manage_meds")

    row = db.query(PatientBaseline).filter(PatientBaseline.elderly_id == elderly_id).first() or PatientBaseline(
        elderly_id=elderly_id
    )
    for key, value in data.model_dump().items():
        setattr(row, key, value)
    row.updated_by_user_id = current_user.id
    db.add(row)
    db.commit()
    values, row = vitals.get_baseline(db, elderly_id)
    return _out(elderly_id, values, row)
