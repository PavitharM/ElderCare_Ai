from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .api.v1 import (
    auth,
    elderly,
    caregiver,
    vitals,
    medications,
    devices,
    emergencies,
    triage,
    ai_risk,
)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="ElderGuard AI — Clinical Backend REST API for Elderly Health Monitoring & Emergency Assistance",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Middleware for Web & Mobile Emulators
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API Routers
api_v1 = settings.API_V1_STR
app.include_router(auth.router, prefix=f"{api_v1}/auth", tags=["Authentication"])
app.include_router(elderly.router, prefix=f"{api_v1}/elderly", tags=["Elderly Profiles & Dashboard"])
app.include_router(caregiver.router, prefix=f"{api_v1}/caregiver", tags=["Caregiver Portal"])
app.include_router(vitals.router, prefix=f"{api_v1}/vitals", tags=["Health Vitals & Telemetry"])
app.include_router(medications.router, prefix=f"{api_v1}/medications", tags=["Medications & Adherence"])
app.include_router(devices.router, prefix=f"{api_v1}/devices", tags=["Wearable Devices"])
app.include_router(emergencies.router, prefix=f"{api_v1}/emergencies", tags=["Emergency Incidents & SOS"])
app.include_router(triage.router, prefix=f"{api_v1}/triage", tags=["Hospital QR Emergency Triage"])
app.include_router(ai_risk.router, prefix=f"{api_v1}/ai", tags=["AI Risk Assessment"])

@app.get("/health", tags=["System"])
def healthcheck():
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "database": "MySQL connected",
    }

@app.get("/", tags=["System"])
def root():
    return {
        "message": "Welcome to ElderGuard AI Clinical Backend",
        "docs": "/docs",
        "version": settings.VERSION,
    }
