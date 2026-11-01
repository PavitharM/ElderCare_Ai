from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ....core.config import settings
from ....core.time import as_utc
from ....db.session import get_db
from ....models.elderly import ElderlyProfile
from ....schemas.elderly import TriageSummaryOut
from ....services import triage
from ...deps import get_current_elderly

router = APIRouter()


@router.post("/generate-token")
def generate_triage_token(elderly: ElderlyProfile = Depends(get_current_elderly), db: Session = Depends(get_db)):
    """Issues a new hospital QR token and revokes any previous one (FR-04)."""
    record = triage.generate(db, elderly)
    return {
        "status": "success",
        "qr_token": record.token,
        "qr_url": triage.qr_url(record.token),
        "expires_at": as_utc(record.expires_at).isoformat(),
        "instruction": f"Clinic staff can open this QR without logging in for {settings.QR_TOKEN_TTL_HOURS} hours.",
    }


@router.post("/revoke")
def revoke_triage_tokens(elderly: ElderlyProfile = Depends(get_current_elderly), db: Session = Depends(get_db)):
    return {"status": "success", "revoked": triage.revoke_all(db, elderly.id)}


@router.get("/summary/{token}", response_model=TriageSummaryOut)
def get_triage_summary(token: str, db: Session = Depends(get_db)):
    """Zero-login, read-only JSON summary (FR-23). The printable page is served at /qr/{token}."""
    try:
        return triage.summary(db, token)
    except triage.TokenError as err:
        raise triage.raise_http(err)
