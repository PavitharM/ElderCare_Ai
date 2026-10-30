from typing import Optional, List
from pydantic import BaseModel, Field

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: str
    full_name: str
    linking_code: Optional[str] = None

class TokenPayload(BaseModel):
    sub: Optional[str] = None
    role: Optional[str] = None

class LoginRequest(BaseModel):
    username: str = Field(..., description="Phone number or Email")
    password: str

class ElderlyRegisterRequest(BaseModel):
    full_name: str
    phone: str
    password: str
    age: int
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
    full_name: str
    email: Optional[str] = None
    phone: str
    password: str
    relationship_to_elder: str
    elderly_linking_code: Optional[str] = None
