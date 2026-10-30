from typing import List
from datetime import datetime
from pydantic import BaseModel, ConfigDict

class RiskAssessmentOut(BaseModel):
    risk_level: str # "low", "moderate", "high"
    status_label: str # "Low Risk - Stable"
    confidence_score: float # 0.92
    vital_score: float
    adherence_score: float
    fall_risk_score: float
    contributing_factors: List[str]
    disclaimer: str
    calculated_at: datetime

    model_config = ConfigDict(from_attributes=True)
