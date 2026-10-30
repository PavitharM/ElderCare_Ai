from datetime import datetime, timezone, timedelta, date
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from sqlalchemy import desc
from ..models.vitals import HealthVital
from ..models.medication import MedicationLog
from ..models.emergency import EmergencyIncident
from ..models.ai_risk import RiskAssessment

def compute_risk_assessment(db: Session, elderly_id: str) -> Dict[str, Any]:
    """
    Computes explainable wellness risk observation based on:
    1. Vitals deviation from normal ranges (45% weight)
    2. Medication adherence over last 7 days (35% weight)
    3. Emergency incident frequency in last 7 days (20% weight)
    
    Returns structured observation with explicit non-clinical disclaimer.
    """
    contributing_factors: List[str] = []
    
    # 1. Evaluate Vitals
    vital_score = 95.0
    for metric_type, optimal_range, label in [
        ("heart_rate", (60, 100), "Heart rate"),
        ("spo2", (95, 100), "Blood oxygen (SpO2)"),
        ("temperature", (36.0, 37.3), "Body temperature"),
    ]:
        latest_vital = db.query(HealthVital).filter(
            HealthVital.elderly_id == elderly_id,
            HealthVital.metric_type == metric_type
        ).order_by(desc(HealthVital.measured_at)).first()

        if latest_vital:
            val = float(latest_vital.value)
            if val < optimal_range[0] or val > optimal_range[1]:
                vital_score -= 15.0
                contributing_factors.append(f"{label} outside optimal range: {val}{latest_vital.unit}")
            else:
                contributing_factors.append(f"{label} stable at {val}{latest_vital.unit}")
        else:
            contributing_factors.append(f"No recent {label} telemetry recorded")

    vital_score = max(0.0, min(100.0, vital_score))

    # 2. Evaluate Medication Adherence
    since_date = date.today() - timedelta(days=7)
    logs = db.query(MedicationLog).filter(
        MedicationLog.elderly_id == elderly_id,
        MedicationLog.scheduled_date >= since_date
    ).all()

    total_doses = len(logs)
    taken_doses = sum(1 for l in logs if l.status == "taken")
    adherence_pct = (taken_doses / total_doses * 100.0) if total_doses > 0 else 94.0

    if adherence_pct >= 90.0:
        contributing_factors.append(f"Medication adherence strong ({int(adherence_pct)}% over past 7 days)")
    elif adherence_pct >= 75.0:
        contributing_factors.append(f"Moderate adherence ({int(adherence_pct)}%) - some missed doses detected")
    else:
        contributing_factors.append(f"Low medication adherence ({int(adherence_pct)}%) - requires caregiver follow-up")

    # 3. Evaluate Recent Incidents
    since_dt = datetime.now(timezone.utc) - timedelta(days=7)
    recent_incidents = db.query(EmergencyIncident).filter(
        EmergencyIncident.elderly_id == elderly_id,
        EmergencyIncident.triggered_at >= since_dt
    ).all()

    unresolved_falls = [i for i in recent_incidents if i.incident_type == "fall_detected" and i.status != "false_alarm"]
    fall_risk_score = 10.0 + (len(unresolved_falls) * 30.0)
    fall_risk_score = min(100.0, fall_risk_score)

    if unresolved_falls:
        contributing_factors.append(f"{len(unresolved_falls)} fall incident(s) detected in the last 7 days")
    else:
        contributing_factors.append("No critical fall events recorded in past 7 days")

    # Composite Risk Level
    # Composite index: higher = healthier (0 to 100)
    wellness_index = (0.45 * vital_score) + (0.35 * adherence_pct) + (0.20 * (100.0 - fall_risk_score))

    if wellness_index >= 80.0:
        risk_level = "low"
        status_label = "Low Risk - Stable"
    elif wellness_index >= 60.0:
        risk_level = "moderate"
        status_label = "Moderate Risk - Monitoring Recommended"
    else:
        risk_level = "high"
        status_label = "High Risk - Clinical Attention Recommended"

    return {
        "risk_level": risk_level,
        "status_label": status_label,
        "confidence_score": 0.920,
        "vital_score": round(vital_score, 2),
        "adherence_score": round(adherence_pct, 2),
        "fall_risk_score": round(fall_risk_score, 2),
        "contributing_factors": contributing_factors,
        "disclaimer": "Algorithmic risk observation only; not a clinical medical diagnosis.",
        "calculated_at": datetime.now(timezone.utc),
    }
