import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, JSON, Enum, UniqueConstraint
from sqlalchemy.orm import relationship
from ..core.database import Base

class CaregiverProfile(Base):
    __tablename__ = "caregiver_profiles"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    relationship_to_elder = Column(String(64), nullable=True) # e.g. "Son & Primary Caregiver"
    notification_preferences = Column(JSON, default=lambda: {"sms": True, "push": True, "call": True})
    avatar_url = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="caregiver_profile")
    elderly_links = relationship("CaregiverElderlyLink", back_populates="caregiver", cascade="all, delete-orphan")

class CaregiverElderlyLink(Base):
    __tablename__ = "caregiver_elderly_links"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    caregiver_id = Column(String(36), ForeignKey("caregiver_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(Enum("pending", "active", "revoked", name="link_status_enum"), default="active", nullable=False)
    permissions = Column(JSON, default=lambda: {"can_view_vitals": True, "can_manage_meds": True, "receive_alerts": True})
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        UniqueConstraint("caregiver_id", "elderly_id", name="uq_caregiver_elderly"),
    )

    caregiver = relationship("CaregiverProfile", back_populates="elderly_links")
    elderly = relationship("ElderlyProfile", back_populates="caregiver_links")
