import random
import string
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ...core.database import get_db
from ...core.security import verify_password, get_password_hash, create_access_token
from ...models.user import User
from ...models.elderly import ElderlyProfile, EmergencyContact
from ...models.caregiver import CaregiverProfile, CaregiverElderlyLink
from ...schemas.auth import (
    Token,
    LoginRequest,
    ElderlyRegisterRequest,
    CaregiverRegisterRequest,
)
from ..deps import get_current_user

router = APIRouter()

def generate_linking_code() -> str:
    digits = "".join(random.choices(string.digits, k=4))
    letters = "".join(random.choices(string.ascii_uppercase, k=2))
    return f"EG-{digits}-{letters}"

@router.post("/login", response_model=Token)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    # Support login via phone or email
    user = db.query(User).filter(
        (User.phone == request.username) | (User.email == request.username)
    ).first()

    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/phone or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Account is deactivated")

    linking_code = None
    if user.elderly_profile:
        linking_code = user.elderly_profile.linking_code

    access_token = create_access_token(subject=user.id, role=user.role)
    return Token(
        access_token=access_token,
        token_type="bearer",
        role=user.role,
        user_id=user.id,
        full_name=user.full_name,
        linking_code=linking_code,
    )

@router.post("/register/elderly", response_model=Token)
def register_elderly(request: ElderlyRegisterRequest, db: Session = Depends(get_db)):
    # Check phone duplicate
    if db.query(User).filter(User.phone == request.phone).first():
        raise HTTPException(status_code=400, detail="Phone number is already registered")

    user_id = str(uuid.uuid4())
    user = User(
        id=user_id,
        phone=request.phone,
        hashed_password=get_password_hash(request.password),
        full_name=request.full_name,
        role="elderly",
        is_active=True,
    )
    db.add(user)
    db.flush()

    linking_code = generate_linking_code()
    elderly_profile = ElderlyProfile(
        id=str(uuid.uuid4()),
        user_id=user.id,
        age=request.age,
        gender=request.gender,
        blood_group=request.blood_group,
        address=request.address,
        linking_code=linking_code,
        chronic_conditions=request.chronic_conditions,
        allergies=request.allergies,
        primary_doctor=request.primary_doctor,
        avatar_url="assets/images/avatar_kamala_perera.jpg",
    )
    db.add(elderly_profile)
    db.flush()

    contact = EmergencyContact(
        id=str(uuid.uuid4()),
        elderly_id=elderly_profile.id,
        name=request.emergency_contact_name,
        relationship=request.emergency_contact_relation,
        phone=request.emergency_contact_phone,
        priority_order=1,
    )
    db.add(contact)
    db.commit()

    access_token = create_access_token(subject=user.id, role=user.role)
    return Token(
        access_token=access_token,
        token_type="bearer",
        role=user.role,
        user_id=user.id,
        full_name=user.full_name,
        linking_code=linking_code,
    )

@router.post("/register/caregiver", response_model=Token)
def register_caregiver(request: CaregiverRegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.phone == request.phone).first():
        raise HTTPException(status_code=400, detail="Phone number is already registered")
    if request.email and db.query(User).filter(User.email == request.email).first():
        raise HTTPException(status_code=400, detail="Email is already registered")

    user_id = str(uuid.uuid4())
    user = User(
        id=user_id,
        phone=request.phone,
        email=request.email,
        hashed_password=get_password_hash(request.password),
        full_name=request.full_name,
        role="caregiver",
        is_active=True,
    )
    db.add(user)
    db.flush()

    caregiver_profile = CaregiverProfile(
        id=str(uuid.uuid4()),
        user_id=user.id,
        relationship_to_elder=request.relationship_to_elder,
        avatar_url="assets/images/avatar_nimal_perera.jpg",
    )
    db.add(caregiver_profile)
    db.flush()

    # Link elderly if code provided
    if request.elderly_linking_code:
        elderly = db.query(ElderlyProfile).filter(
            ElderlyProfile.linking_code == request.elderly_linking_code
        ).first()
        if elderly:
            link = CaregiverElderlyLink(
                id=str(uuid.uuid4()),
                caregiver_id=caregiver_profile.id,
                elderly_id=elderly.id,
                status="active",
            )
            db.add(link)

    db.commit()

    access_token = create_access_token(subject=user.id, role=user.role)
    return Token(
        access_token=access_token,
        token_type="bearer",
        role=user.role,
        user_id=user.id,
        full_name=user.full_name,
    )

@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "phone": current_user.phone,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "role": current_user.role,
    }
