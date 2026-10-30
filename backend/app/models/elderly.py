import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, JSON, Boolean
from sqlalchemy.orm import relationship as orm_relationship
from ..core.database import Base

class ElderlyProfile(Base):
    __tablename__ = "elderly_profiles"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    age = Column(Integer, nullable=False)
    gender = Column(String(16), nullable=False)
    blood_group = Column(String(8), nullable=False)
    address = Column(String(255), nullable=False)
    linking_code = Column(String(16), unique=True, index=True, nullable=False)
    chronic_conditions = Column(JSON, default=list) # e.g. ["Hypertension", "Type 2 Diabetes"]
    allergies = Column(JSON, default=list) # e.g. ["Penicillin"]
    primary_doctor = Column(String(128), nullable=True)
    avatar_url = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = orm_relationship("User", back_populates="elderly_profile")
    caregiver_links = orm_relationship("CaregiverElderlyLink", back_populates="elderly", cascade="all, delete-orphan")
    emergency_contacts = orm_relationship("EmergencyContact", back_populates="elderly", cascade="all, delete-orphan")
    wearable_devices = orm_relationship("WearableDevice", back_populates="elderly", cascade="all, delete-orphan")
    vitals = orm_relationship("HealthVital", back_populates="elderly", cascade="all, delete-orphan")
    medications = orm_relationship("Medication", back_populates="elderly", cascade="all, delete-orphan")
    emergencies = orm_relationship("EmergencyIncident", back_populates="elderly", cascade="all, delete-orphan")
    risk_assessments = orm_relationship("RiskAssessment", back_populates="elderly", cascade="all, delete-orphan")
    qr_tokens = orm_relationship("HospitalQRToken", back_populates="elderly", cascade="all, delete-orphan")

class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(128), nullable=False)
    relationship = Column(String(64), nullable=False)
    phone = Column(String(32), nullable=False)
    priority_order = Column(Integer, default=1)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    elderly = orm_relationship("ElderlyProfile", back_populates="emergency_contacts")

class HospitalQRToken(Base):
    __tablename__ = "hospital_qr_tokens"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    elderly_id = Column(String(36), ForeignKey("elderly_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    token = Column(String(64), unique=True, index=True, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_revoked = Column(Boolean, default=False)
    access_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    elderly = orm_relationship("ElderlyProfile", back_populates="qr_tokens")
