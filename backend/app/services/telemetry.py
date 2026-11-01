"""Wearable telemetry relayed by the phone over REST (FR-06, FR-07, FR-09, FR-14)."""

from fastapi import HTTPException
from sqlalchemy.orm import Session

from ..core.time import utcnow
from ..models.elderly import ElderlyProfile
from ..models.vitals import WearableDevice
from ..schemas.vitals import TelemetryBatchRequest, TelemetryResult
from . import emergency, risk, vitals


def paired_device(db: Session, elderly: ElderlyProfile, device_id: str) -> WearableDevice:
    device = (
        db.query(WearableDevice)
        .filter(WearableDevice.elderly_id == elderly.id, WearableDevice.mac_address == device_id)
        .first()
    )
    if not device:
        raise HTTPException(status_code=403, detail="Wearable is not paired with this account")
    return device


def ingest(db: Session, elderly: ElderlyProfile, batch: TelemetryBatchRequest) -> TelemetryResult:
    device = paired_device(db, elderly, batch.device_id)
    device.connection_status = "connected"
    device.last_heartbeat_at = utcnow()
    if batch.battery_level is not None:
        device.battery_level = batch.battery_level

    baseline, _ = vitals.get_baseline(db, elderly.id)
    accepted, rejected = 0, []
    for reading in batch.readings:
        error = vitals.validation_error(reading.metric_type, reading.value)
        if error:
            rejected.append(error)  # sensor glitch: skip it, keep the rest of the packet
            continue
        vitals.store_reading(
            db,
            elderly.id,
            reading.metric_type,
            reading.value,
            baseline,
            measured_at=reading.measured_at,
            device_id=device.id,
        )
        accepted += 1

    incident = None
    if batch.trigger == "fall" and batch.fall:
        incident = emergency.create_fall(db, elderly, impact_g=batch.fall.impact_g)

    db.flush()
    assessment, critical_incident = risk.evaluate(db, elderly.id)
    db.commit()

    chosen = incident or critical_incident
    return TelemetryResult(
        accepted=accepted,
        rejected=rejected,
        risk_level=assessment.risk_level,
        incident_id=chosen.id if chosen else None,
    )
