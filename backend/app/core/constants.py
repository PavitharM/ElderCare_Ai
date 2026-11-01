"""Domain constants shared by services, the risk engine and seed data."""

# Risk categories required by SRS FR-13
RISK_NORMAL = "normal"
RISK_WARNING = "warning"
RISK_HIGH = "high_risk"
RISK_CRITICAL = "critical"
RISK_LEVELS = (RISK_NORMAL, RISK_WARNING, RISK_HIGH, RISK_CRITICAL)
RISK_LABELS = {
    RISK_NORMAL: "Normal - Stable",
    RISK_WARNING: "Warning - Monitoring Recommended",
    RISK_HIGH: "High Risk - Caregiver Attention Needed",
    RISK_CRITICAL: "Critical - Emergency Response Triggered",
}

DISCLAIMER = "Decision-support observation only; not a medical diagnosis."

VITAL_METRICS = ("heart_rate", "spo2", "temperature")
TELEMETRY_METRICS = VITAL_METRICS + ("activity_level",)

METRIC_UNITS = {
    "heart_rate": "BPM",
    "spo2": "%",
    "temperature": "°C",
    "activity_level": "mg",
    "blood_pressure": "mmHg",
}

# Physically plausible sensor bounds (FR-28). Values outside are rejected as sensor errors.
PLAUSIBLE_BOUNDS = {
    "heart_rate": (20.0, 250.0),
    "spo2": (50.0, 100.0),
    "temperature": (30.0, 45.0),
    "activity_level": (0.0, 16000.0),
    "blood_pressure": (40.0, 260.0),
}

# Default clinical ranges, used when no doctor-defined baseline exists (FR-27).
DEFAULT_BASELINE = {
    "heart_rate_min": 60.0,
    "heart_rate_max": 100.0,
    "spo2_min": 95.0,
    "temperature_min": 36.0,
    "temperature_max": 37.5,
}

# Hard critical limits, independent of personal baselines.
CRITICAL_LIMITS = {
    "heart_rate": (40.0, 130.0),
    "spo2_min": 90.0,
    "temperature": (35.0, 39.0),
}

METRIC_LABELS = {
    "heart_rate": "Heart Rate",
    "spo2": "Blood Oxygen",
    "temperature": "Body Temp",
}
