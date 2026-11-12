"""Registration, login and caregiver linking (FR-01, FR-03)."""

import secrets
import string
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..core.security import get_password_hash, verify_password
from ..models.caregiver import CaregiverElderlyLink, CaregiverProfile
from ..models.elderly import ElderlyProfile, EmergencyContact
from ..models.user import User
from ..schemas.auth import CaregiverRegisterRequest, ElderlyRegisterRequest


def _unique_linking_code(db: Session) -> str:
    for _ in range(20):
        digits = "".join(secrets.choice(string.digits) for _ in range(4))
        letters = "".join(secrets.choice(string.ascii_uppercase) for _ in range(2))
        code = f"EG-{digits}-{letters}"
        if not db.query(ElderlyProfile.id).filter(ElderlyProfile.linking_code == code).first():
            return code
    raise HTTPException(status_code=500, detail="Could not allocate a linking code, please retry")


def _ensure_unique(db: Session, phone: str, email: Optional[str]) -> None:
    if db.query(User.id).filter(User.phone == phone).first():
        raise HTTPException(status_code=409, detail="Phone number is already registered")
    if email and db.query(User.id).filter(User.email == email).first():
        raise HTTPException(status_code=409, detail="Email is already registered")


def authenticate(db: Session, username: str, password: str) -> User:
    user = db.query(User).filter((User.phone == username) | (User.email == username)).first()
    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect phone/email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is deactivated")
    return user


def register_elderly(db: Session, req: ElderlyRegisterRequest) -> User:
    _ensure_unique(db, req.phone, None)
    user = User(
        phone=req.phone,
        hashed_password=get_password_hash(req.password),
        full_name=req.full_name,
        role="elderly",
    )
    db.add(user)
    db.flush()
    profile = ElderlyProfile(
        user_id=user.id,
        age=req.age,
        gender=req.gender,
        blood_group=req.blood_group,
        address=req.address,
        linking_code=_unique_linking_code(db),
        chronic_conditions=req.chronic_conditions,
        allergies=req.allergies,
        primary_doctor=req.primary_doctor,
    )
    db.add(profile)
    db.flush()
    db.add(
        EmergencyContact(
            elderly_id=profile.id,
            name=req.emergency_contact_name,
            relationship=req.emergency_contact_relation,
            phone=req.emergency_contact_phone,
            priority_order=1,
        )
    )
    db.commit()
    db.refresh(user)
    return user


def register_caregiver(db: Session, req: CaregiverRegisterRequest) -> User:
    _ensure_unique(db, req.phone, req.email)
    elderly = None
    if req.elderly_linking_code:
        elderly = find_by_linking_code(db, req.elderly_linking_code)

    user = User(
        phone=req.phone,
        email=req.email,
        hashed_password=get_password_hash(req.password),
        full_name=req.full_name,
        role="caregiver",
    )
    db.add(user)
    db.flush()
    profile = CaregiverProfile(user_id=user.id, relationship_to_elder=req.relationship_to_elder)
    db.add(profile)
    db.flush()
    if elderly:
        db.add(CaregiverElderlyLink(caregiver_id=profile.id, elderly_id=elderly.id, status="active"))
    db.commit()
    db.refresh(user)
    return user


def find_by_linking_code(db: Session, code: str) -> ElderlyProfile:
    elderly = db.query(ElderlyProfile).filter(ElderlyProfile.linking_code == code.strip().upper()).first()
    if not elderly:
        raise HTTPException(status_code=404, detail="Invalid linking code. Elderly profile not found.")
    return elderly


def link_caregiver(db: Session, caregiver: CaregiverProfile, elderly: ElderlyProfile) -> bool:
    """Returns True when a new link was created (or a revoked one re-activated)."""
    link = (
        db.query(CaregiverElderlyLink)
        .filter(CaregiverElderlyLink.caregiver_id == caregiver.id, CaregiverElderlyLink.elderly_id == elderly.id)
        .first()
    )
    if link and link.status == "active":
        return False
    if link:
        link.status = "active"
    else:
        db.add(CaregiverElderlyLink(caregiver_id=caregiver.id, elderly_id=elderly.id, status="active"))
    db.commit()
    return True
