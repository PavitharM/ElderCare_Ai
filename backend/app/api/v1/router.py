from fastapi import APIRouter

from .endpoints import (
    auth,
    baselines,
    caregiver,
    devices,
    elderly,
    emergencies,
    medications,
    notifications,
    risk,
    triage,
    vitals,
)

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(elderly.router, prefix="/elderly", tags=["Elderly Profile & Dashboard"])
api_router.include_router(caregiver.router, prefix="/caregiver", tags=["Caregiver Portal"])
api_router.include_router(vitals.router, prefix="/vitals", tags=["Health Vitals & Telemetry"])
api_router.include_router(baselines.router, prefix="/baselines", tags=["Doctor-Defined Baselines"])
api_router.include_router(medications.router, prefix="/medications", tags=["Medications & Adherence"])
api_router.include_router(devices.router, prefix="/devices", tags=["Wearable Devices"])
api_router.include_router(emergencies.router, prefix="/emergencies", tags=["Emergency Incidents & SOS"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Push Notifications"])
api_router.include_router(triage.router, prefix="/triage", tags=["Hospital QR Triage"])
api_router.include_router(risk.router, prefix="/ai", tags=["AI Risk Assessment"])
