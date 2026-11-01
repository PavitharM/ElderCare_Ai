"""Personalized risk assessment (SRS FR-11, FR-12, FR-13).

Pure logic with no database access: the risk service gathers inputs, this module decides.

Approach (explainable, rule + statistics hybrid):
  1. Each latest vital is checked against the doctor-defined baseline and hard critical limits.
  2. Anomaly detection: z-score of the latest value against the patient's own 7-day history.
  3. Contextual factors: recent falls, active SOS, inactivity after a fall, medication adherence.
  4. Factors are combined into Normal / Warning / High Risk / Critical.
The output is decision support, never a diagnosis (NFR-15).
"""

from dataclasses import dataclass, field
from statistics import mean, pstdev
from typing import Dict, List, Optional, Tuple

from ..core.constants import (
    CRITICAL_LIMITS,
    RISK_CRITICAL,
    RISK_HIGH,
    RISK_LABELS,
    RISK_NORMAL,
    RISK_WARNING,
    VITAL_METRICS,
)

ANOMALY_Z_THRESHOLD = 3.0
MIN_HISTORY_FOR_ANOMALY = 10
LOW_ADHERENCE_PCT = 75.0
INACTIVITY_MG = 30.0  # mean dynamic acceleration below this = no movement


@dataclass
class LatestVital:
    value: float
    unit: str
    age_minutes: float


@dataclass
class FallEvent:
    age_minutes: float
    cancelled: bool


@dataclass
class RiskInputs:
    baseline: Dict[str, float]
    latest: Dict[str, LatestVital]
    history: Dict[str, List[float]]
    stale_after_minutes: float
    doses_taken: int = 0
    doses_total: int = 0
    falls_7d: List[FallEvent] = field(default_factory=list)
    active_sos: bool = False
    recent_activity_mg: List[float] = field(default_factory=list)


@dataclass
class RiskResult:
    risk_level: str
    status_label: str
    confidence_score: float
    vital_score: float
    adherence_score: Optional[float]
    fall_risk_score: float
    contributing_factors: List[str]
    anomalies: List[dict]


def classify_vital(metric: str, value: float, baseline: Dict[str, float]) -> Tuple[str, str]:
    """Return (status, human text). Status: optimal | normal | warning | critical."""
    if metric == "heart_rate":
        lo, hi = CRITICAL_LIMITS["heart_rate"]
        if value < lo or value > hi:
            return "critical", "Critical Heart Rate"
        bmin, bmax = baseline["heart_rate_min"], baseline["heart_rate_max"]
        if value > bmax:
            return "warning", "Elevated Heart Rate"
        if value < bmin:
            return "warning", "Low Heart Rate (Bradycardia)"
        mid_lo, mid_hi = bmin + (bmax - bmin) * 0.1, bmin + (bmax - bmin) * 0.6
        return ("optimal", "Optimal Resting Pulse") if mid_lo <= value <= mid_hi else ("normal", "Normal & Regular")

    if metric == "spo2":
        if value < CRITICAL_LIMITS["spo2_min"]:
            return "critical", "Critical Hypoxia"
        if value < baseline["spo2_min"]:
            return "warning", "Mild Hypoxia"
        return ("optimal", "Optimal Saturation") if value >= 97 else ("normal", "Acceptable Saturation")

    if metric == "temperature":
        lo, hi = CRITICAL_LIMITS["temperature"]
        if value < lo:
            return "critical", "Hypothermia Risk"
        if value >= hi:
            return "critical", "High Fever"
        if value > baseline["temperature_max"]:
            return "warning", "Mild Fever"
        if value < baseline["temperature_min"]:
            return "warning", "Below Normal Temperature"
        return ("optimal", "Healthy Range") if 36.3 <= value <= 36.9 else ("normal", "Normal Range")

    return "normal", "Measured"


def _detect_anomaly(metric: str, value: float, history: List[float]) -> Optional[dict]:
    if len(history) < MIN_HISTORY_FOR_ANOMALY:
        return None
    mu, sigma = mean(history), pstdev(history)
    if sigma < 1e-6:
        return None
    z = (value - mu) / sigma
    if abs(z) < ANOMALY_Z_THRESHOLD:
        return None
    return {"metric": metric, "value": value, "baseline_mean": round(mu, 2), "z_score": round(z, 2)}


def assess(inputs: RiskInputs) -> RiskResult:
    factors: List[str] = []
    anomalies: List[dict] = []
    warnings = 0
    criticals = 0
    fresh_metrics = 0

    # 1-2. Vitals vs baseline, plus personal anomaly detection
    for metric in VITAL_METRICS:
        reading = inputs.latest.get(metric)
        label = metric.replace("_", " ").replace("spo2", "SpO2").capitalize()
        if reading is None:
            factors.append(f"No {label} data recorded yet")
            continue
        if reading.age_minutes > inputs.stale_after_minutes:
            factors.append(f"{label} data is stale ({int(reading.age_minutes)} min old) - wearable may be disconnected")
            continue
        fresh_metrics += 1
        status, text = classify_vital(metric, reading.value, inputs.baseline)
        if status == "critical":
            criticals += 1
            factors.append(f"{text}: {reading.value:g} {reading.unit}")
        elif status == "warning":
            warnings += 1
            factors.append(f"{text}: {reading.value:g} {reading.unit} (outside personal range)")
        else:
            factors.append(f"{label} within personal range at {reading.value:g} {reading.unit}")

        anomaly = _detect_anomaly(metric, reading.value, inputs.history.get(metric, []))
        if anomaly:
            anomalies.append(anomaly)
            factors.append(
                f"Unusual {label} for this patient (z={anomaly['z_score']}, 7-day mean {anomaly['baseline_mean']})"
            )

    vital_score = max(0.0, 100.0 - warnings * 20.0 - criticals * 45.0 - len(anomalies) * 10.0)

    # 3a. Falls and SOS
    active_falls = [f for f in inputs.falls_7d if not f.cancelled]
    fall_last_hour = any(f.age_minutes <= 60 for f in active_falls)
    fall_last_day = any(f.age_minutes <= 1440 for f in active_falls)
    fall_risk_score = min(100.0, len(active_falls) * 25.0 + (40.0 if fall_last_day else 0.0))
    if active_falls:
        factors.append(f"{len(active_falls)} confirmed fall event(s) in the last 7 days")
    else:
        factors.append("No confirmed falls in the last 7 days")

    inactive = bool(inputs.recent_activity_mg) and max(inputs.recent_activity_mg) < INACTIVITY_MG
    if inactive and fall_last_hour:
        factors.append("No movement detected after a recent fall")

    if inputs.active_sos:
        factors.append("Manual SOS request is active")

    # 3b. Medication adherence (context only, never causation - FR-18)
    adherence: Optional[float] = None
    if inputs.doses_total > 0:
        adherence = round(inputs.doses_taken / inputs.doses_total * 100.0, 2)
        if adherence < LOW_ADHERENCE_PCT:
            factors.append(f"Low medication adherence ({adherence:.0f}% over 7 days)")
        else:
            factors.append(f"Medication adherence {adherence:.0f}% over 7 days")

    # 4. Combine
    if criticals or inputs.active_sos or (fall_last_hour and (warnings or inactive)):
        level = RISK_CRITICAL
    elif fall_last_day or warnings >= 2 or (warnings and anomalies):
        level = RISK_HIGH
    elif warnings or anomalies or (adherence is not None and adherence < LOW_ADHERENCE_PCT) or active_falls:
        level = RISK_WARNING
    else:
        level = RISK_NORMAL

    confidence = round(0.4 + 0.2 * fresh_metrics, 3)  # more fresh data = more confidence

    return RiskResult(
        risk_level=level,
        status_label=RISK_LABELS[level],
        confidence_score=min(confidence, 1.0),
        vital_score=round(vital_score, 2),
        adherence_score=adherence,
        fall_risk_score=round(fall_risk_score, 2),
        contributing_factors=factors,
        anomalies=anomalies,
    )
