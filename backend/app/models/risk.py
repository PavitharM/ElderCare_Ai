import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Enum, ForeignKey, JSON, Numeric, String
from sqlalchemy.orm import relationship

from ..core.constants import DISCLAIMER, RISK_LEVELS, RISK_NORMAL
from ..db.base import Base


class RiskAssessment(Base):
    __tablename__ = "risk_assessments"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    risk_level = Column(Enum(*RISK_LEVELS, name="risk_level_enum"), default=RISK_NORMAL, nullable=False)
    status_label = Column(String(64), nullable=False)
    confidence_score = Column(Numeric(4, 3), default=0)  # 0.000 - 1.000, based on data completeness
    vital_score = Column(Numeric(5, 2), default=100)  # 0 - 100, higher = healthier
    adherence_score = Column(Numeric(5, 2), nullable=True)  # null when no doses were scheduled
    fall_risk_score = Column(Numeric(5, 2), default=0)  # 0 - 100, higher = riskier
    contributing_factors = Column(JSON, default=list)
    anomalies = Column(JSON, default=list)  # FR-11: [{metric, value, baseline_mean, z_score}]
    disclaimer = Column(String(255), default=DISCLAIMER)
    calculated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True)

    elderly = relationship("ElderlyProfile", back_populates="risk_assessments")
