"""Authorization rules: who may act on which elderly profile (SRS FR-02, FR-22, NFR-05/06)."""

from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models.caregiver import CaregiverElderlyLink
from ..models.elderly import ElderlyProfile
from ..models.user import User


def forbidden(detail: str = "You are not authorized to access this profile") -> HTTPException:
    return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=detail)


def own_elderly_profile(user: User) -> ElderlyProfile:
    if user.role != "elderly" or not user.elderly_profile:
        raise forbidden("This action is only available to elderly users")
    return user.elderly_profile


def active_link(db: Session, user: User, elderly_id: str) -> Optional[CaregiverElderlyLink]:
    if user.role != "caregiver" or not user.caregiver_profile:
        return None
    return (
        db.query(CaregiverElderlyLink)
        .filter(
            CaregiverElderlyLink.caregiver_id == user.caregiver_profile.id,
            CaregiverElderlyLink.elderly_id == elderly_id,
            CaregiverElderlyLink.status == "active",
        )
        .first()
    )


def resolve_target_elderly(
    db: Session,
    user: User,
    elderly_id: Optional[str],
    permission: Optional[str] = None,
) -> ElderlyProfile:
    """Elderly users always act on their own profile. Caregivers must name a linked profile
    (or have exactly one link) and hold the required link permission."""
    if user.role == "elderly":
        return own_elderly_profile(user)

    if user.role != "caregiver" or not user.caregiver_profile:
        raise forbidden()

    if not elderly_id:
        links = [l for l in user.caregiver_profile.elderly_links if l.status == "active"]
        if len(links) != 1:
            raise HTTPException(status_code=400, detail="elderly_id query parameter is required")
        link = links[0]
    else:
        link = active_link(db, user, elderly_id)
        if link is None:
            raise forbidden()

    if permission and not link.allows(permission):
        raise forbidden(f"Missing caregiver permission: {permission}")
    return link.elderly


def ensure_can_access(db: Session, user: User, elderly_id: str, permission: Optional[str] = None) -> None:
    if user.role == "elderly":
        if not user.elderly_profile or user.elderly_profile.id != elderly_id:
            raise forbidden()
        return
    link = active_link(db, user, elderly_id)
    if link is None or (permission and not link.allows(permission)):
        raise forbidden()
// end of one