from datetime import datetime, timezone, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from ...core.database import get_db
from ...models.user import User
from ...models.elderly import ElderlyProfile
from ...models.vitals import HealthVital
from ...schemas.vitals import VitalsDashboardOut, VitalReadingItem, IngestVitalRequest
from ..deps import get_current_user

router = APIRouter()

METRIC_CONFIG = {
    "heart_rate": {
        "label": "Heart Rate",
        "unit": "BPM",
        "normal_range": "60 - 100 BPM",
        "optimal_min": 60, "optimal_max": 80,
        "normal_min": 55, "normal_max": 95,
        "warning_max": 110,
    },
    "spo2": {
        "label": "Blood Oxygen",
        "unit": "%",
        "normal_range": "95% - 100%",
        "optimal_min": 97, "optimal_max": 100,
        "normal_min": 95, "normal_max": 100,
        "warning_min": 90,
    },
    "temperature": {
        "label": "Body Temp",
        "unit": "°C",
        "normal_range": "36.1°C - 37.2°C",
        "optimal_min": 36.3, "optimal_max": 36.9,
        "normal_min": 36.0, "normal_max": 37.3,
        "warning_max": 38.0,
    },
}

def classify_vital_status(metric: str, value: float) -> tuple[str, str]:
    if metric == "heart_rate":
        if 60 <= value <= 80:
            return "optimal", "Optimal Resting Pulse"
        elif 55 <= value <= 100:
            return "normal", "Normal & Regular"
        elif value > 100:
            return "warning", "Elevated Heart Rate"
        else:
            return "warning", "Low Heart Rate (Bradycardia)"
    elif metric == "spo2":
        if value >= 97:
            return "optimal", "Optimal Saturation"
        elif value >= 95:
            return "normal", "Acceptable Saturation"
        elif value >= 90:
            return "warning", "Mild Hypoxia"
        else:
            return "critical", "Critical Hypoxia"
    elif metric == "temperature":
        if 36.3 <= value <= 36.9:
            return "optimal", "Healthy Range"
        elif 36.0 <= value <= 37.2:
            return "normal", "Normal Range"
        elif value > 37.5:
            return "warning", "Mild Fever"
        else:
            return "normal", "Normal Range"
    return "normal", "Measured"

@router.get("/latest", response_model=VitalsDashboardOut)
def get_latest_vitals(
    elderly_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_elderly_id = None
    if current_user.role == "elderly":
        if not current_user.elderly_profile:
            raise HTTPException(status_code=404, detail="Elderly profile not found")
        target_elderly_id = current_user.elderly_profile.id
    elif current_user.role == "caregiver":
        if not elderly_id:
            raise HTTPException(status_code=400, detail="elderly_id query parameter required for caregiver")
        target_elderly_id = elderly_id

    items = {}
    last_updated = datetime.now(timezone.utc)

    for metric_key, cfg in METRIC_CONFIG.items():
        # Get latest reading
        latest = db.query(HealthVital).filter(
            HealthVital.elderly_id == target_elderly_id,
            HealthVital.metric_type == metric_key
        ).order_by(desc(HealthVital.measured_at)).first()

        # Get 7-day history points
        since = datetime.now(timezone.utc) - timedelta(days=7)
        history_records = db.query(HealthVital).filter(
            HealthVital.elderly_id == target_elderly_id,
            HealthVital.metric_type == metric_key,
            HealthVital.measured_at >= since
        ).order_by(HealthVital.measured_at).all()

        history_points = [float(r.value) for r in history_records][-7:]
        if not history_points and latest:
            history_points = [float(latest.value)]

        val_str = str(latest.value) if latest else "0"
        status, status_text = classify_vital_status(metric_key, float(latest.value) if latest else 0)

        items[metric_key] = VitalReadingItem(
            label=cfg["label"],
            value=val_str,
            unit=cfg["unit"],
            status_text=status_text,
            status=status,
            normal_range=cfg["normal_range"],
            history_7_days=history_points,
        )

    return VitalsDashboardOut(
        heart_rate=items["heart_rate"],
        spo2=items["spo2"],
        temperature=items["temperature"],
        last_updated=last_updated,
    )

@router.get("/trends")
def get_vital_trends(
    days: int = Query(7, ge=1, le=30),
    elderly_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_elderly_id = current_user.elderly_profile.id if current_user.role == "elderly" else elderly_id
    since = datetime.now(timezone.utc) - timedelta(days=days)

    trends = {}
    for metric_key, cfg in METRIC_CONFIG.items():
        records = db.query(HealthVital).filter(
            HealthVital.elderly_id == target_elderly_id,
            HealthVital.metric_type == metric_key,
            HealthVital.measured_at >= since
        ).order_by(HealthVital.measured_at).all()

        values = [float(r.value) for r in records]
        avg_val = round(sum(values) / len(values), 1) if values else 0.0
        min_val = min(values) if values else 0.0
        max_val = max(values) if values else 0.0

        trends[metric_key] = {
            "label": cfg["label"],
            "unit": cfg["unit"],
            "average": avg_val,
            "min": min_val,
            "max": max_val,
            "data_points": [{"value": float(r.value), "measured_at": r.measured_at.isoformat()} for r in records],
        }

    return trends

@router.post("/ingest")
def ingest_vital_reading(
    reading: IngestVitalRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not current_user.elderly_profile:
        raise HTTPException(status_code=400, detail="Only registered elderly profiles can ingest vitals")

    status, _ = classify_vital_status(reading.metric_type, reading.value)
    vital = HealthVital(
        elderly_id=current_user.elderly_profile.id,
        metric_type=reading.metric_type,
        value=reading.value,
        secondary_value=reading.secondary_value,
        unit=reading.unit,
        status=status,
        source=reading.source,
        measured_at=datetime.now(timezone.utc),
    )
    db.add(vital)
    db.commit()

    return {"status": "success", "vital_id": vital.id, "classified_status": status}
