from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, ConfigDict

class EmergencyIncidentCreate(BaseModel):
    incident_type: str = "fall_detected" # "fall_detected", "manual_sos"
    title: str
    description: Optional[str] = None
    impact_force_g: Optional[float] = None
    location_text: str = "Living Room (Ground Floor)"
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class NotificationDeliveryOut(BaseModel):
    id: str
    contact_name: str
    contact_phone: str
    channel: str
    delivery_status: str
    status_message: Optional[str]

    model_config = ConfigDict(from_attributes=True)

class EmergencyIncidentOut(BaseModel):
    id: str
    incident_type: str
    title: str
    description: Optional[str]
    impact_force_g: Optional[float]
    location_text: str
    severity: str
    status: str
    triggered_at: datetime
    resolved_at: Optional[datetime]
    notifications: List[NotificationDeliveryOut] = []

    model_config = ConfigDict(from_attributes=True)
