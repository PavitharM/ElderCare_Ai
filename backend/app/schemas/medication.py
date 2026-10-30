from typing import Optional, List
from datetime import time, date, datetime
from pydantic import BaseModel, ConfigDict

class MedicationCreate(BaseModel):
    name: str
    dosage: str
    schedule_period: str # "Morning", "Afternoon", "Evening", "Night"
    scheduled_time: str # "08:00:00"
    instruction: Optional[str] = "After meal"

class MedicationItemOut(BaseModel):
    id: str
    name: str
    dosage: str
    schedule_period: str
    time: str
    instruction: Optional[str]
    is_taken: bool

    model_config = ConfigDict(from_attributes=True)

class MedicationAdherenceOut(BaseModel):
    adherence_percentage: int
    streak_days: int
    taken_doses_this_week: int
    total_doses_this_week: int
    missed_doses_this_week: int
