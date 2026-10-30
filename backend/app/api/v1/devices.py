from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ...core.database import get_db
from ...models.user import User
from ...models.vitals import WearableDevice
from ...schemas.vitals import WearableDeviceOut, PairDeviceRequest
from ..deps import get_current_user

router = APIRouter()

@router.get("/my-device", response_model=WearableDeviceOut)
def get_my_device(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not current_user.elderly_profile:
        raise HTTPException(status_code=400, detail="Only elderly profiles have wearable devices")

    device = db.query(WearableDevice).filter(
        WearableDevice.elderly_id == current_user.elderly_profile.id
    ).first()

    if not device:
        # Default mock-paired device
        device = WearableDevice(
            elderly_id=current_user.elderly_profile.id,
            device_name="ElderGuard Band V2 #8492",
            mac_address="C4:72:8F:90:3B:12",
            battery_level=92,
            connection_status="connected",
            firmware_version="v2.1.4",
            is_simulated=True,
        )
        db.add(device)
        db.commit()
        db.refresh(device)

    return device

@router.post("/pair", response_model=WearableDeviceOut)
def pair_device(
    pair_req: PairDeviceRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not current_user.elderly_profile:
        raise HTTPException(status_code=400, detail="Only elderly profiles can pair wearable devices")

    device = db.query(WearableDevice).filter(
        WearableDevice.elderly_id == current_user.elderly_profile.id
    ).first()

    now = datetime.now(timezone.utc)
    if not device:
        device = WearableDevice(
            elderly_id=current_user.elderly_profile.id,
            device_name=pair_req.device_name,
            mac_address=pair_req.mac_address,
            battery_level=98,
            connection_status="connected",
            last_heartbeat_at=now,
            is_simulated=False,
        )
        db.add(device)
    else:
        device.device_name = pair_req.device_name
        device.mac_address = pair_req.mac_address
        device.connection_status = "connected"
        device.last_heartbeat_at = now

    db.commit()
    db.refresh(device)
    return device
