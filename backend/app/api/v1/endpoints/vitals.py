from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ....db.session import get_db
from ....models.elderly import ElderlyProfile
from ....schemas.vitals import IngestVitalRequest, TelemetryBatchRequest, TelemetryResult, VitalsDashboardOut
from ....services import risk, telemetry, vitals
from ...deps import get_current_elderly, target_elderly

router = APIRouter()


@router.get("/latest", response_model=VitalsDashboardOut)
def get_latest_vitals(
    elderly: ElderlyProfile = Depends(target_elderly("can_view_vitals")),
    db: Session = Depends(get_db),
):
    return vitals.dashboard(db, elderly.id)


@router.get("/trends")
def get_vital_trends(
    days: int = Query(7, ge=1, le=31),
    elderly: ElderlyProfile = Depends(target_elderly("can_view_vitals")),
    db: Session = Depends(get_db),
):
    """Daily / weekly / monthly trend data (FR-10)."""
    return vitals.trends(db, elderly.id, days)


@router.post("/telemetry", response_model=TelemetryResult)
def ingest_telemetry(
    batch: TelemetryBatchRequest,
    elderly: ElderlyProfile = Depends(get_current_elderly),
    db: Session = Depends(get_db),
):
    """Wearable packet relayed by the elderly user's phone. Stores readings, handles falls and re-runs risk."""
    return telemetry.ingest(db, elderly, batch)


@router.post("/ingest")
def ingest_vital_reading(
    reading: IngestVitalRequest,
    elderly: ElderlyProfile = Depends(get_current_elderly),
    db: Session = Depends(get_db),
):
    """Single manual reading (kept for manual entry and older clients)."""
    baseline, _ = vitals.get_baseline(db, elderly.id)
    vital = vitals.store_reading(
        db,
        elderly.id,
        reading.metric_type,
        reading.value,
        baseline,
        measured_at=reading.measured_at,
        source=reading.source,
        secondary_value=reading.secondary_value,
    )
    db.flush()
    assessment, _ = risk.evaluate(db, elderly.id)
    db.commit()
    return {"status": "success", "vital_id": vital.id, "classified_status": vital.status, "risk_level": assessment.risk_level}
