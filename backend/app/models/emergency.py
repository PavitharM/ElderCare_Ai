import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import relationship

from ..db.base import Base


def _utcnow():
    return datetime.now(timezone.utc)


class EmergencyIncident(Base):
    __tablename__ = "emergency_incidents"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    incident_type = Column(Enum("fall_detected", "manual_sos", "critical_vital", "geofence", name="incident_type_enum"), nullable=False)
    title = Column(String(128), nullable=False)
    description = Column(Text, nullable=True)
    impact_force_g = Column(Numeric(4, 2), nullable=True)
    location_text = Column(String(255), default="Home")
    latitude = Column(Numeric(10, 8), nullable=True)
    longitude = Column(Numeric(11, 8), nullable=True)
    severity = Column(Enum("critical", "high", "warning", "info", name="incident_severity_enum"), default="critical")
    status = Column(
        Enum("active_countdown", "dispatched", "resolved", "false_alarm", name="incident_status_enum"),
        default="active_countdown",
    )
    # Falls wait for the elderly user to respond before escalating (SRS FR-14).
    escalate_at = Column(DateTime(timezone=True), nullable=True)
    triggered_at = Column(DateTime(timezone=True), default=_utcnow, index=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)

    elderly = relationship("ElderlyProfile", back_populates="emergencies")
    notifications = relationship("IncidentNotification", back_populates="incident", cascade="all, delete-orphan")


class IncidentNotification(Base):
    __tablename__ = "incident_notifications"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    incident_id = Column(String(36), ForeignKey("emergency_incidents.id", ondelete="CASCADE"), nullable=False, index=True)
    recipient_user_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    contact_name = Column(String(128), nullable=False)
    contact_phone = Column(String(32), nullable=True)
    channel = Column(Enum("sms", "call", "push", name="notification_channel_enum"), default="push")
    delivery_status = Column(Enum("simulated_sent", "queued", "sent", "failed", name="delivery_status_enum"), default="queued")
    status_message = Column(String(255), nullable=True)
    dispatched_at = Column(DateTime(timezone=True), default=_utcnow)

    incident = relationship("EmergencyIncident", back_populates="notifications")
