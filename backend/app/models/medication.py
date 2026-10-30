import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Date, Time, ForeignKey, Enum, UniqueConstraint
from sqlalchemy.orm import relationship
from ..core.database import Base

class Medication(Base):
    __tablename__ = "medications"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(128), nullable=False) # e.g. "Metformin 500mg"
    dosage = Column(String(64), nullable=False) # e.g. "1 Tablet"
    schedule_period = Column(Enum("Morning", "Afternoon", "Evening", "Night", name="schedule_period_enum"), nullable=False)
    scheduled_time = Column(Time, nullable=False) # e.g. 08:00:00
    instruction = Column(String(255), nullable=True) # e.g. "After Breakfast"
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    elderly = relationship("ElderlyProfile", back_populates="medications")
    logs = relationship("MedicationLog", back_populates="medication", cascade="all, delete-orphan")

class MedicationLog(Base):
    __tablename__ = "medication_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    medication_id = Column(String(36), ForeignKey("medications.id", ondelete="CASCADE"), nullable=False, index=True)
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    scheduled_date = Column(Date, nullable=False, index=True)
    scheduled_time = Column(Time, nullable=False)
    status = Column(Enum("taken", "missed", "skipped", "pending", name="dose_status_enum"), default="pending")
    confirmed_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        UniqueConstraint("medication_id", "scheduled_date", "scheduled_time", name="uq_med_date_time"),
    )

    medication = relationship("Medication", back_populates="logs")
