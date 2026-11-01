from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class EmergencyIncidentCreate(BaseModel):
    title: str = Field("Potential Fall Detected", max_length=128)
    description: Optional[str] = None
    impact_force_g: Optional[float] = Field(None, ge=0, le=16)
    location_text: str = Field("Home", max_length=255)
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class SosRequest(BaseModel):
    location_text: str = Field("Home", max_length=255)
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class NotificationDeliveryOut(BaseModel):
    id: str
    contact_name: str
    contact_phone: Optional[str]
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
    location_text: Optional[str]
    severity: str
    status: str
    escalate_at: Optional[datetime] = None
    triggered_at: datetime
    resolved_at: Optional[datetime]
    notifications: List[NotificationDeliveryOut] = []

    model_config = ConfigDict(from_attributes=True)
