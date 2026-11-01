from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from ....core.security import create_access_token
from ....db.session import get_db
from ....models.user import User
from ....schemas.auth import CaregiverRegisterRequest, ElderlyRegisterRequest, LoginRequest, Token, UserOut
from ....services import accounts
from ...deps import get_current_user

router = APIRouter()


def _token_for(user: User) -> Token:
    return Token(
        access_token=create_access_token(subject=user.id, role=user.role),
        role=user.role,
        user_id=user.id,
        full_name=user.full_name,
        linking_code=user.elderly_profile.linking_code if user.elderly_profile else None,
    )


@router.post("/login", response_model=Token, summary="Login with phone/email + password (JSON)")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    return _token_for(accounts.authenticate(db, request.username, request.password))


@router.post("/token", response_model=Token, include_in_schema=False)
def login_form(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """OAuth2 form login used by the Swagger 'Authorize' button."""
    return _token_for(accounts.authenticate(db, form.username, form.password))


@router.post("/register/elderly", response_model=Token, status_code=201)
def register_elderly(request: ElderlyRegisterRequest, db: Session = Depends(get_db)):
    return _token_for(accounts.register_elderly(db, request))


@router.post("/register/caregiver", response_model=Token, status_code=201)
def register_caregiver(request: CaregiverRegisterRequest, db: Session = Depends(get_db)):
    return _token_for(accounts.register_caregiver(db, request))


@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return UserOut(
        id=current_user.id,
        phone=current_user.phone,
        email=current_user.email,
        full_name=current_user.full_name,
        role=current_user.role,
    )
