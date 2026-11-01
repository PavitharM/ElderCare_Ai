from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ....core.time import utcnow
from ....db.session import get_db
from ....models.elderly import ElderlyProfile
from ....models.vitals import WearableDevice
from ....schemas.vitals import DeviceStatusUpdate, PairDeviceRequest, WearableDeviceOut
from ...deps import get_current_elderly, target_elderly

router = APIRouter()


def _device(db: Session, elderly_id: str):
    return db.query(WearableDevice).filter(WearableDevice.elderly_id == elderly_id).first()


@router.get("/my-device", response_model=WearableDeviceOut)
def get_my_device(elderly: ElderlyProfile = Depends(target_elderly()), db: Session = Depends(get_db)):
    device = _device(db, elderly.id)
    if not device:
        raise HTTPException(status_code=404, detail="No wearable paired yet")
    return device


@router.post("/pair", response_model=WearableDeviceOut)
def pair_device(
    pair_req: PairDeviceRequest,
    elderly: ElderlyProfile = Depends(get_current_elderly),
    db: Session = Depends(get_db),
):
    """Register (or replace) the wearable for this elderly user (FR-05). One wearable per profile."""
    taken = (
        db.query(WearableDevice)
        .filter(WearableDevice.mac_address == pair_req.mac_address, WearableDevice.elderly_id != elderly.id)
        .first()
    )
    if taken:
        raise HTTPException(status_code=409, detail="This wearable is already paired with another account")

    device = _device(db, elderly.id) or WearableDevice(elderly_id=elderly.id)
    device.device_name = pair_req.device_name
    device.mac_address = pair_req.mac_address
    device.firmware_version = pair_req.firmware_version or device.firmware_version or "unknown"
    if pair_req.battery_level is not None:
        device.battery_level = pair_req.battery_level
    device.connection_status = "connected"
    device.last_heartbeat_at = utcnow()
    device.is_simulated = False
    db.add(device)
    db.commit()
    db.refresh(device)
    return device


@router.put("/my-device/status", response_model=WearableDeviceOut)
def update_device_status(
    update: DeviceStatusUpdate,
    elderly: ElderlyProfile = Depends(get_current_elderly),
    db: Session = Depends(get_db),
):
    """Phone reports BLE connect/disconnect so caregivers see real connection state (FR-07, FR-08)."""
    device = _device(db, elderly.id)
    if not device:
        raise HTTPException(status_code=404, detail="No wearable paired yet")
    device.connection_status = update.connection_status
    if update.battery_level is not None:
        device.battery_level = update.battery_level
    device.last_heartbeat_at = utcnow()
    db.commit()
    db.refresh(device)
    return device
