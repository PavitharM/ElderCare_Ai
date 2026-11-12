import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, Enum, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import relationship

from ..db.base import Base


def _utcnow():
    return datetime.now(timezone.utc)


class WearableDevice(Base):
    __tablename__ = "wearable_devices"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    device_name = Column(String(64), nullable=False)
    mac_address = Column(String(32), index=True, nullable=False)  # BLE remote id reported by the phone
    battery_level = Column(Integer, default=100)
    connection_status = Column(Enum("connected", "disconnected", "syncing", name="device_status_enum"), default="disconnected")
    last_heartbeat_at = Column(DateTime(timezone=True), default=_utcnow)
    firmware_version = Column(String(32), default="unknown")
    is_simulated = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=_utcnow)

    elderly = relationship("ElderlyProfile", back_populates="wearable_devices")
    vitals = relationship("HealthVital", back_populates="device")


class HealthVital(Base):
    __tablename__ = "health_vitals"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    device_id = Column(String(36), ForeignKey("wearable_devices.id", ondelete="SET NULL"), nullable=True, index=True)
    metric_type = Column(
        Enum("heart_rate", "spo2", "temperature", "blood_pressure", "activity_level", name="vital_metric_enum"),
        nullable=False,
        index=True,
    )
    value = Column(Numeric(8, 2), nullable=False)
    secondary_value = Column(Numeric(6, 2), nullable=True)  # diastolic for blood pressure
    unit = Column(String(16), nullable=False)
    status = Column(Enum("optimal", "normal", "warning", "critical", name="metric_status_enum"), default="normal")
    source = Column(String(32), default="wearable_ble")
    measured_at = Column(DateTime(timezone=True), default=_utcnow, index=True)

    elderly = relationship("ElderlyProfile", back_populates="vitals")
    device = relationship("WearableDevice", back_populates="vitals")
