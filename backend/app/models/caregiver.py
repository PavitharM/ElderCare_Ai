import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Enum, ForeignKey, JSON, String, UniqueConstraint
from sqlalchemy.orm import relationship

from ..db.base import Base

DEFAULT_LINK_PERMISSIONS = {"can_view_vitals": True, "can_manage_meds": True, "receive_alerts": True}


def _utcnow():
    return datetime.now(timezone.utc)


class CaregiverProfile(Base):
    __tablename__ = "caregiver_profiles"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    relationship_to_elder = Column(String(64), nullable=True)
    notification_preferences = Column(JSON, default=lambda: {"push": True})
    avatar_url = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=_utcnow)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    user = relationship("User", back_populates="caregiver_profile")
    elderly_links = relationship("CaregiverElderlyLink", back_populates="caregiver", cascade="all, delete-orphan")


class CaregiverElderlyLink(Base):
    __tablename__ = "caregiver_elderly_links"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    caregiver_id = Column(String(36), ForeignKey("caregiver_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(Enum("pending", "active", "revoked", name="link_status_enum"), default="active", nullable=False)
    permissions = Column(JSON, default=lambda: dict(DEFAULT_LINK_PERMISSIONS))
    created_at = Column(DateTime(timezone=True), default=_utcnow)

    __table_args__ = (UniqueConstraint("caregiver_id", "elderly_id", name="uq_caregiver_elderly"),)

    caregiver = relationship("CaregiverProfile", back_populates="elderly_links")
    elderly = relationship("ElderlyProfile", back_populates="caregiver_links")

    def allows(self, permission: str) -> bool:
        return bool((self.permissions or DEFAULT_LINK_PERMISSIONS).get(permission, False))
