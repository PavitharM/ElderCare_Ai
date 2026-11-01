from datetime import datetime
from typing import List, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field


class VitalReadingItem(BaseModel):
    label: str
    value: str
    unit: str
    status_text: str
    status: str  # "optimal", "normal", "warning", "critical"
    normal_range: str
    history_7_days: List[float] = []
    measured_at: Optional[datetime] = None
    is_stale: bool = True  # FR-08: true when no reading within VITAL_STALE_AFTER_MINUTES


class VitalsDashboardOut(BaseModel):
    heart_rate: VitalReadingItem
    spo2: VitalReadingItem
    temperature: VitalReadingItem
    blood_pressure: Optional[VitalReadingItem] = None
    last_updated: Optional[datetime] = None


MetricType = Literal["heart_rate", "spo2", "temperature", "blood_pressure", "activity_level"]


class IngestVitalRequest(BaseModel):
    """Single manual/legacy reading."""

    metric_type: MetricType
    value: float
    secondary_value: Optional[float] = None
    unit: Optional[str] = None
    source: str = "manual"
    measured_at: Optional[datetime] = None


class TelemetryReading(BaseModel):
    metric_type: MetricType
    value: float
    measured_at: Optional[datetime] = None


class TelemetryFall(BaseModel):
    impact_g: float = Field(..., ge=0, le=16)


class TelemetryBatchRequest(BaseModel):
    """One BLE packet relayed by the phone (see docs/SUMMARY.md, BLE protocol)."""

    device_id: str = Field(..., description="BLE remote id of the paired wearable")
    trigger: Literal["periodic", "abnormal", "fall", "sync"] = "periodic"
    sequence: Optional[int] = None
    battery_level: Optional[int] = Field(None, ge=0, le=100)
    readings: List[TelemetryReading] = []
    fall: Optional[TelemetryFall] = None


class TelemetryResult(BaseModel):
    accepted: int
    rejected: List[str]
    risk_level: str
    incident_id: Optional[str] = None


class WearableDeviceOut(BaseModel):
    id: str
    device_name: str
    mac_address: str
    battery_level: int
    connection_status: str
    last_heartbeat_at: Optional[datetime]
    firmware_version: Optional[str]
    is_simulated: bool

    model_config = ConfigDict(from_attributes=True)


class PairDeviceRequest(BaseModel):
    device_name: str = Field(..., max_length=64)
    mac_address: str = Field(..., max_length=32, description="BLE remote id")
    firmware_version: Optional[str] = Field(None, max_length=32)
    battery_level: Optional[int] = Field(None, ge=0, le=100)


class DeviceStatusUpdate(BaseModel):
    connection_status: Literal["connected", "disconnected", "syncing"]
    battery_level: Optional[int] = Field(None, ge=0, le=100)
