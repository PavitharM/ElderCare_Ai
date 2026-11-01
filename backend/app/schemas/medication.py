from typing import List, Literal, Optional

from pydantic import BaseModel, Field, field_validator

SchedulePeriod = Literal["Morning", "Afternoon", "Evening", "Night"]


def normalize_time(v: str) -> str:
    parts = v.split(":")
    if len(parts) < 2 or not all(p.isdigit() for p in parts):
        raise ValueError("scheduled_time must be HH:MM")
    h, m = int(parts[0]), int(parts[1])
    if not (0 <= h < 24 and 0 <= m < 60):
        raise ValueError("scheduled_time out of range")
    return f"{h:02d}:{m:02d}"


def validate_days(v: Optional[List[int]]) -> Optional[List[int]]:
    if v is not None and any(d < 0 or d > 6 for d in v):
        raise ValueError("days_of_week values must be 0-6")
    return v


class MedicationCreate(BaseModel):
    name: str = Field(..., max_length=128)
    dosage: str = Field(..., max_length=64)
    schedule_period: SchedulePeriod
    scheduled_time: str = Field(..., description="Local time HH:MM or HH:MM:SS")
    frequency: Literal["daily", "weekly"] = "daily"
    days_of_week: Optional[List[int]] = Field(None, description="0=Mon..6=Sun, required for weekly")
    instruction: Optional[str] = Field(None, max_length=255)

    _time = field_validator("scheduled_time")(lambda cls, v: normalize_time(v))
    _days = field_validator("days_of_week")(lambda cls, v: validate_days(v))


class MedicationUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=128)
    dosage: Optional[str] = Field(None, max_length=64)
    schedule_period: Optional[SchedulePeriod] = None
    scheduled_time: Optional[str] = None
    frequency: Optional[Literal["daily", "weekly"]] = None
    days_of_week: Optional[List[int]] = None
    instruction: Optional[str] = Field(None, max_length=255)
    is_active: Optional[bool] = None

    _time = field_validator("scheduled_time")(lambda cls, v: normalize_time(v) if v is not None else v)
    _days = field_validator("days_of_week")(lambda cls, v: validate_days(v))


class MedicationItemOut(BaseModel):
    id: str
    name: str
    dosage: str
    schedule_period: str
    time: str
    instruction: Optional[str]
    is_taken: bool
    status: str = "pending"  # taken | missed | pending | skipped (FR-17)
    frequency: str = "daily"


class MedicationAdherenceOut(BaseModel):
    adherence_percentage: int
    streak_days: int
    taken_doses_this_week: int
    total_doses_this_week: int
    missed_doses_this_week: int
