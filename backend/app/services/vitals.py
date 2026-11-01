"""Health measurements: validation, storage, baselines, dashboard and trends (FR-08..FR-10, FR-27, FR-28)."""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple

from fastapi import HTTPException
from sqlalchemy import desc
from sqlalchemy.orm import Session

from ..ai.risk_engine import classify_vital
from ..core.config import settings
from ..core.constants import DEFAULT_BASELINE, METRIC_LABELS, METRIC_UNITS, PLAUSIBLE_BOUNDS, VITAL_METRICS
from ..core.time import as_utc, utcnow
from ..models.elderly import PatientBaseline
from ..models.vitals import HealthVital
from ..schemas.vitals import VitalReadingItem, VitalsDashboardOut


# ---------- Baselines (FR-27) ----------

def get_baseline(db: Session, elderly_id: str) -> Tuple[Dict[str, float], Optional[PatientBaseline]]:
    row = db.query(PatientBaseline).filter(PatientBaseline.elderly_id == elderly_id).first()
    if not row:
        return dict(DEFAULT_BASELINE), None
    return {k: float(getattr(row, k)) for k in DEFAULT_BASELINE}, row


def normal_range_text(metric: str, baseline: Dict[str, float]) -> str:
    if metric == "heart_rate":
        return f"{baseline['heart_rate_min']:g} - {baseline['heart_rate_max']:g} BPM"
    if metric == "spo2":
        return f"{baseline['spo2_min']:g}% - 100%"
    return f"{baseline['temperature_min']:g}°C - {baseline['temperature_max']:g}°C"


# ---------- Validation & storage (FR-09, FR-28) ----------

def validation_error(metric: str, value: float) -> Optional[str]:
    lo, hi = PLAUSIBLE_BOUNDS[metric]
    if not (lo <= value <= hi):
        return f"{metric}={value} is outside the plausible sensor range {lo}-{hi}"
    return None


def store_reading(
    db: Session,
    elderly_id: str,
    metric: str,
    value: float,
    baseline: Dict[str, float],
    *,
    measured_at: Optional[datetime] = None,
    device_id: Optional[str] = None,
    source: str = "wearable_ble",
    secondary_value: Optional[float] = None,
) -> HealthVital:
    error = validation_error(metric, value)
    if error:
        raise HTTPException(status_code=422, detail=error)
    now = utcnow()
    when = as_utc(measured_at) if measured_at else now
    if when > now + timedelta(minutes=5):
        when = now  # clock skew guard: never store future readings
    status = classify_vital(metric, value, baseline)[0] if metric in VITAL_METRICS else "normal"
    vital = HealthVital(
        elderly_id=elderly_id,
        device_id=device_id,
        metric_type=metric,
        value=value,
        secondary_value=secondary_value,
        unit=METRIC_UNITS[metric],
        status=status,
        source=source,
        measured_at=when,
    )
    db.add(vital)
    return vital


# ---------- Queries ----------

def latest(db: Session, elderly_id: str, metric: str) -> Optional[HealthVital]:
    return (
        db.query(HealthVital)
        .filter(HealthVital.elderly_id == elderly_id, HealthVital.metric_type == metric)
        .order_by(desc(HealthVital.measured_at))
        .first()
    )


def values_since(db: Session, elderly_id: str, metric: str, since: datetime) -> List[HealthVital]:
    return (
        db.query(HealthVital)
        .filter(
            HealthVital.elderly_id == elderly_id,
            HealthVital.metric_type == metric,
            HealthVital.measured_at >= since,
        )
        .order_by(HealthVital.measured_at)
        .all()
    )


def age_minutes(v: HealthVital) -> float:
    return (utcnow() - as_utc(v.measured_at)).total_seconds() / 60.0


def is_stale(v: Optional[HealthVital]) -> bool:
    return v is None or age_minutes(v) > settings.VITAL_STALE_AFTER_MINUTES


def daily_points(records: List[HealthVital], days: int = 7) -> List[float]:
    """One averaged value per day for the sparkline charts."""
    buckets: Dict[str, List[float]] = {}
    for r in records:
        buckets.setdefault(as_utc(r.measured_at).date().isoformat(), []).append(float(r.value))
    return [round(sum(v) / len(v), 1) for _, v in sorted(buckets.items())][-days:]


def dashboard(db: Session, elderly_id: str) -> VitalsDashboardOut:
    baseline, _ = get_baseline(db, elderly_id)
    since = utcnow() - timedelta(days=7)
    items: Dict[str, VitalReadingItem] = {}
    last_updated: Optional[datetime] = None

    for metric in VITAL_METRICS:
        last = latest(db, elderly_id, metric)
        history = daily_points(values_since(db, elderly_id, metric, since))
        if last:
            status, text = classify_vital(metric, float(last.value), baseline)
            measured = as_utc(last.measured_at)
            last_updated = max(last_updated, measured) if last_updated else measured
        else:
            status, text = "normal", "No data yet"
        stale = is_stale(last)
        items[metric] = VitalReadingItem(
            label=METRIC_LABELS[metric],
            value=f"{float(last.value):g}" if last else "--",
            unit=METRIC_UNITS[metric],
            status_text=f"{text} (last reading {int(age_minutes(last))} min ago)" if last and stale else text,
            status=status,
            normal_range=normal_range_text(metric, baseline),
            history_7_days=history,
            measured_at=as_utc(last.measured_at) if last else None,
            is_stale=stale,
        )

    return VitalsDashboardOut(
        heart_rate=items["heart_rate"],
        spo2=items["spo2"],
        temperature=items["temperature"],
        last_updated=last_updated,
    )


def trends(db: Session, elderly_id: str, days: int) -> dict:
    since = utcnow() - timedelta(days=days)
    result = {}
    for metric in VITAL_METRICS + ("activity_level",):
        records = values_since(db, elderly_id, metric, since)
        values = [float(r.value) for r in records]
        result[metric] = {
            "label": METRIC_LABELS.get(metric, "Activity Level"),
            "unit": METRIC_UNITS[metric],
            "average": round(sum(values) / len(values), 1) if values else None,
            "min": min(values) if values else None,
            "max": max(values) if values else None,
            "daily_average": daily_points(records, days),
            "data_points": [{"value": float(r.value), "measured_at": as_utc(r.measured_at).isoformat()} for r in records],
        }
    return result


def summary_24h(db: Session, elderly_id: str) -> Dict[str, Dict[str, float]]:
    since = utcnow() - timedelta(hours=24)
    out = {}
    for metric in VITAL_METRICS:
        values = [float(r.value) for r in values_since(db, elderly_id, metric, since)]
        if values:
            out[metric] = {"min": min(values), "max": max(values), "avg": round(sum(values) / len(values), 1)}
    return out
