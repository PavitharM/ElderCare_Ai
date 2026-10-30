from typing import Optional, List, Dict
from pydantic import BaseModel, ConfigDict
from .elderly import ElderlyProfileOut

class CaregiverProfileOut(BaseModel):
    id: str
    user_id: str
    name: str
    email: Optional[str]
    phone: str
    relationship_to_elder: Optional[str]
    notification_preferences: Dict
    avatar_url: Optional[str]

    model_config = ConfigDict(from_attributes=True)

class LinkElderlyRequest(BaseModel):
    linking_code: str # e.g. "EG-8829-KP"

class LinkedElderlyCard(BaseModel):
    id: str
    name: str
    age: int
    relationship: str
    avatar_url: Optional[str]
    linking_code: str
    vitals_status: str # "optimal", "normal", "warning", "critical"
    heart_rate: str
    spo2: str
    temperature: str
    risk_level: str
    wearable_connected: bool
    battery_level: int
