import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Numeric, DateTime, ForeignKey, Enum, JSON
from sqlalchemy.orm import relationship
from ..core.database import Base

class RiskAssessment(Base):
    __tablename__ = "risk_assessments"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    risk_level = Column(Enum("low", "moderate", "high", name="risk_level_enum"), default="low", nullable=False)
    status_label = Column(String(64), default="Low Risk - Stable")
    confidence_score = Column(Numeric(4, 3), default=0.920) # 0.000 - 1.000
    vital_score = Column(Numeric(4, 2), default=95.0)
    adherence_score = Column(Numeric(4, 2), default=94.0)
    fall_risk_score = Column(Numeric(4, 2), default=10.0)
    contributing_factors = Column(JSON, default=list) # e.g. ["Heart rate steady at 74 BPM", "Medication adherence at 94%"]
    disclaimer = Column(String(255), default="Algorithmic risk observation only; not a clinical medical diagnosis.")
    calculated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True)

    elderly = relationship("ElderlyProfile", back_populates="risk_assessments")
