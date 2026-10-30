import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Numeric, DateTime, ForeignKey, Enum, Boolean
from sqlalchemy.orm import relationship
from ..core.database import Base

class WearableDevice(Base):
    __tablename__ = "wearable_devices"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    device_name = Column(String(64), nullable=False) # e.g. "ElderGuard Band V2 #8492"
    mac_address = Column(String(32), index=True, nullable=False)
    battery_level = Column(Integer, default=100)
    connection_status = Column(Enum("connected", "disconnected", "syncing", name="device_status_enum"), default="connected")
    last_heartbeat_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    firmware_version = Column(String(32), default="v2.1.4")
    is_simulated = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    elderly = relationship("ElderlyProfile", back_populates="wearable_devices")

class HealthVital(Base):
    __tablename__ = "health_vitals"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    metric_type = Column(Enum("heart_rate", "spo2", "temperature", "blood_pressure", name="vital_metric_enum"), nullable=False, index=True)
    value = Column(Numeric(6, 2), nullable=False)
    secondary_value = Column(Numeric(6, 2), nullable=True) # e.g. diastolic for blood pressure
    unit = Column(String(16), nullable=False) # BPM, %, °C, mmHg
    status = Column(Enum("optimal", "normal", "warning", "critical", name="metric_status_enum"), default="normal")
    source = Column(String(32), default="wearable_ble")
    measured_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True)

    elderly = relationship("ElderlyProfile", back_populates="vitals")
