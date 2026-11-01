from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict


class RiskAssessmentOut(BaseModel):
    risk_level: str  # normal | warning | high_risk | critical
    status_label: str
    confidence_score: float
    vital_score: float
    adherence_score: Optional[float]
    fall_risk_score: float
    contributing_factors: List[str]
    anomalies: List[dict] = []
    disclaimer: str
    calculated_at: datetime

    model_config = ConfigDict(from_attributes=True)
