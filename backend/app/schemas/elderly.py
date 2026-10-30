from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, ConfigDict

class EmergencyContactBase(BaseModel):
    name: str
    relationship: str
    phone: str
    priority_order: int = 1

class EmergencyContactOut(EmergencyContactBase):
    id: str
    model_config = ConfigDict(from_attributes=True)

class ElderlyProfileUpdate(BaseModel):
    age: Optional[int] = None
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

    model_config = ConfigDict(from_attributes=True)

class TriageSummaryOut(BaseModel):
    patient_name: str
    age: int
    gender: str
    blood_group: str
    allergies: List[str]
    chronic_conditions: List[str]
    primary_doctor: Optional[str]
    emergency_contacts: List[EmergencyContactOut]
    latest_vitals: dict
    generated_at: datetime
