from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ....db.session import get_db
from ....models.user import PushDeviceToken, User
from ....schemas.notification import PushTokenRequest
from ...deps import get_current_user

router = APIRouter()


@router.post("/device-token", status_code=204)
def register_device_token(
    data: PushTokenRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Register this phone's FCM token so emergency alerts reach it (FR-21)."""
    row = db.query(PushDeviceToken).filter(PushDeviceToken.token == data.token).first()
    if row:
        row.user_id = current_user.id  # token moved to another account on the same phone
        row.platform = data.platform
    else:
        db.add(PushDeviceToken(user_id=current_user.id, token=data.token, platform=data.platform))
    db.commit()


@router.delete("/device-token", status_code=204)
def unregister_device_token(
    data: PushTokenRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db.query(PushDeviceToken).filter(
        PushDeviceToken.token == data.token, PushDeviceToken.user_id == current_user.id
    ).delete()
    db.commit()
