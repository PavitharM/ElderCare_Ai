from typing import List, Optional

from pydantic import BaseModel, Field


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: str
    full_name: str
    linking_code: Optional[str] = None


class LoginRequest(BaseModel):
    username: str = Field(..., description="Phone number or email")
    password: str


class ElderlyRegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=128)
    phone: str = Field(..., min_length=7, max_length=32)
    password: str = Field(..., min_length=6, max_length=128)
    age: int = Field(..., ge=40, le=120)
    gender: str
    blood_group: str
    address: str
    chronic_conditions: List[str] = []
    allergies: List[str] = []
    primary_doctor: Optional[str] = None
    emergency_contact_name: str
    emergency_contact_relation: str
    emergency_contact_phone: str


class CaregiverRegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=128)
    email: Optional[str] = None
    phone: str = Field(..., min_length=7, max_length=32)
    password: str = Field(..., min_length=6, max_length=128)
    relationship_to_elder: str
    elderly_linking_code: Optional[str] = None


class UserOut(BaseModel):
    id: str
    phone: str
    email: Optional[str]
    full_name: str
    role: str
