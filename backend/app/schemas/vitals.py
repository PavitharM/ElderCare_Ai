from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class VitalReadingItem(BaseModel):
    label: str
    value: str
    unit: str
    status_text: str
    status: str # "optimal", "normal", "warning", "critical"
    normal_range: str
    history_7_days: List[float] = []

class VitalsDashboardOut(BaseModel):
    heart_rate: VitalReadingItem
    spo2: VitalReadingItem
    temperature: VitalReadingItem
    blood_pressure: Optional[VitalReadingItem] = None
    last_updated: datetime

class IngestVitalRequest(BaseModel):
    metric_type: str = Field(..., description="heart_rate, spo2, temperature, blood_pressure")
    value: float
    secondary_value: Optional[float] = None
    unit: str
    source: str = "wearable_ble"

class WearableDeviceOut(BaseModel):
    id: str
    device_name: str
    mac_address: str
    battery_level: int
    connection_status: str
    last_heartbeat_at: datetime
    firmware_version: str
    is_simulated: bool

    model_config = ConfigDict(from_attributes=True)

class PairDeviceRequest(BaseModel):
    device_name: str
    mac_address: str
