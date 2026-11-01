import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, Date, DateTime, Enum, ForeignKey, JSON, String, Time, UniqueConstraint
from sqlalchemy.orm import relationship

from ..db.base import Base


def _utcnow():
    return datetime.now(timezone.utc)


class Medication(Base):
    __tablename__ = "medications"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(128), nullable=False)
    dosage = Column(String(64), nullable=False)
    schedule_period = Column(Enum("Morning", "Afternoon", "Evening", "Night", name="schedule_period_enum"), nullable=False)
    scheduled_time = Column(Time, nullable=False)  # local wall-clock time (settings.TIMEZONE)
    # FR-15 frequency: "daily" or "weekly" (weekly uses days_of_week, 0 = Monday)
    frequency = Column(String(16), default="daily", nullable=False)
    days_of_week = Column(JSON, nullable=True)
    instruction = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=_utcnow)

    elderly = relationship("ElderlyProfile", back_populates="medications")
    logs = relationship("MedicationLog", back_populates="medication", cascade="all, delete-orphan")

    def is_due_on(self, weekday: int) -> bool:
        if self.frequency == "weekly":
            return weekday in (self.days_of_week or [])
        return True


class MedicationLog(Base):
    __tablename__ = "medication_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    medication_id = Column(String(36), ForeignKey("medications.id", ondelete="CASCADE"), nullable=False, index=True)
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    scheduled_date = Column(Date, nullable=False, index=True)
    scheduled_time = Column(Time, nullable=False)
    status = Column(Enum("taken", "missed", "skipped", "pending", name="dose_status_enum"), default="pending")
    confirmed_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (UniqueConstraint("medication_id", "scheduled_date", "scheduled_time", name="uq_med_date_time"),)

    medication = relationship("Medication", back_populates="logs")
