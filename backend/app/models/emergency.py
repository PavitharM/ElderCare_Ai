import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Numeric, DateTime, ForeignKey, Enum, Text
from sqlalchemy.orm import relationship
from ..core.database import Base

class EmergencyIncident(Base):
    __tablename__ = "emergency_incidents"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    incident_type = Column(Enum("fall_detected", "manual_sos", "critical_vital", "geofence", name="incident_type_enum"), nullable=False)
    title = Column(String(128), nullable=False)
    description = Column(Text, nullable=True)
    impact_force_g = Column(Numeric(4, 2), nullable=True) # e.g. 2.80 G
    location_text = Column(String(255), default="Living Room (Ground Floor)")
    latitude = Column(Numeric(10, 8), nullable=True)
    longitude = Column(Numeric(11, 8), nullable=True)
    severity = Column(Enum("critical", "high", "warning", "info", name="incident_severity_enum"), default="critical")
    status = Column(Enum("active_countdown", "dispatched", "resolved", "false_alarm", name="incident_status_enum"), default="active_countdown")
    triggered_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)

    elderly = relationship("ElderlyProfile", back_populates="emergencies")
    notifications = relationship("IncidentNotification", back_populates="incident", cascade="all, delete-orphan")

class IncidentNotification(Base):
    __tablename__ = "incident_notifications"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    incident_id = Column(String(36), ForeignKey("emergency_incidents.id", ondelete="CASCADE"), nullable=False, index=True)
    contact_name = Column(String(128), nullable=False)
    contact_phone = Column(String(32), nullable=False)
    channel = Column(Enum("sms", "call", "push", name="notification_channel_enum"), default="sms")
    delivery_status = Column(Enum("simulated_sent", "queued", "sent", "failed", name="delivery_status_enum"), default="simulated_sent")
    status_message = Column(String(255), nullable=True)
    dispatched_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    incident = relationship("EmergencyIncident", back_populates="notifications")
