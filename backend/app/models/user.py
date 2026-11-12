import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, Enum, ForeignKey, String
from sqlalchemy.orm import relationship

from ..db.base import Base


def _utcnow():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, index=True, nullable=True)
    phone = Column(String(32), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(128), nullable=False)
    # "doctor"/"admin" are reserved for future use; the mobile app supports elderly + caregiver only.
    role = Column(Enum("elderly", "caregiver", "doctor", "admin", name="user_role_enum"), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=_utcnow)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    elderly_profile = relationship("ElderlyProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    caregiver_profile = relationship("CaregiverProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    device_tokens = relationship("PushDeviceToken", back_populates="user", cascade="all, delete-orphan")


class PushDeviceToken(Base):
    """Mobile push token (FCM) registered by a logged-in app instance."""

    __tablename__ = "push_device_tokens"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token = Column(String(255), unique=True, nullable=False)
    platform = Column(String(16), default="android", nullable=False)
    created_at = Column(DateTime(timezone=True), default=_utcnow)
    last_seen_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    user = relationship("User", back_populates="device_tokens")
