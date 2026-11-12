from datetime import datetime
from typing import Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator


class EmergencyContactOut(BaseModel):
    id: str
    name: str
    relationship: str
    phone: str
    priority_order: int = 1

    model_config = ConfigDict(from_attributes=True)


class ElderlyProfileUpdate(BaseModel):
    age: Optional[int] = Field(None, ge=40, le=120)
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    address: Optional[str] = None
    chronic_conditions: Optional[List[str]] = None
    allergies: Optional[List[str]] = None
    primary_doctor: Optional[str] = None


class ElderlyProfileOut(BaseModel):
    id: str
    user_id: str
    name: str
    phone: str
    age: int
    gender: str
    blood_group: str
    address: str
    linking_code: str
    chronic_conditions: List[str]
    allergies: List[str]
    primary_doctor: Optional[str] = None
    avatar_url: Optional[str] = None
    emergency_contacts: List[EmergencyContactOut] = []


class BaselineUpdate(BaseModel):
    """Doctor-defined personal ranges (FR-27), entered by the linked caregiver."""

    heart_rate_min: float = Field(..., ge=30, le=120)
    heart_rate_max: float = Field(..., ge=60, le=200)
    spo2_min: float = Field(..., ge=80, le=100)
    temperature_min: float = Field(..., ge=34, le=37.5)
    temperature_max: float = Field(..., ge=36.5, le=40)
    notes: Optional[str] = None
    defined_by: Optional[str] = Field(None, max_length=128, description="Name of the doctor who set the ranges")

    @model_validator(mode="after")
    def check_ranges(self):
        if self.heart_rate_min >= self.heart_rate_max:
            raise ValueError("heart_rate_min must be lower than heart_rate_max")
        if self.temperature_min >= self.temperature_max:
            raise ValueError("temperature_min must be lower than temperature_max")
        return self


class BaselineOut(BaseModel):
    elderly_id: str
    heart_rate_min: float
    heart_rate_max: float
    spo2_min: float
    temperature_min: float
    temperature_max: float
    notes: Optional[str] = None
    defined_by: Optional[str] = None
    is_default: bool
    updated_at: Optional[datetime] = None


class TriageVital(BaseModel):
    value: float
    unit: str
    status: str
    measured_at: datetime


class TriageSummaryOut(BaseModel):
    patient_name: str
    age: int
    gender: str
    blood_group: str
    allergies: List[str]
    chronic_conditions: List[str]
    primary_doctor: Optional[str]
    emergency_contacts: List[EmergencyContactOut]
    latest_vitals: Dict[str, TriageVital]
    vitals_24h: Dict[str, Dict[str, float]]  # metric -> {min, max, avg}
    risk_level: Optional[str] = None
    risk_label: Optional[str] = None
    active_medications: List[str] = []
    generated_at: datetime
    expires_at: datetime
