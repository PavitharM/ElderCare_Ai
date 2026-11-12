from typing import Callable, Optional

from fastapi import Depends, HTTPException, Query, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from ..core.config import settings
from ..core.security import decode_access_token
from ..db.session import get_db
from ..models.elderly import ElderlyProfile
from ..models.user import User
from ..services import access

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/token")


def get_current_user(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials or token expired",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if not payload or not payload.get("sub"):
        raise credentials_exception
    user = db.get(User, payload["sub"])
    if user is None or not user.is_active:
        raise credentials_exception
    return user


def require_role(*allowed_roles: str) -> Callable[..., User]:
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Permission denied for your role")
        return current_user

    return role_checker


def get_current_elderly(current_user: User = Depends(get_current_user)) -> ElderlyProfile:
    return access.own_elderly_profile(current_user)


def target_elderly(permission: Optional[str] = None) -> Callable[..., ElderlyProfile]:
    """Resolve the elderly profile a request acts on, enforcing caregiver links and permissions."""

    def dependency(
        elderly_id: Optional[str] = Query(None, description="Required for caregivers with several linked profiles"),
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> ElderlyProfile:
        return access.resolve_target_elderly(db, current_user, elderly_id, permission)

    return dependency
