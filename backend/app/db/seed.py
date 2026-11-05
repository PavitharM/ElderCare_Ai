"""Seed demo data (README test accounts). Run: python -m app.db.seed"""

import logging
from datetime import time, timedelta

from ..core.constants import METRIC_UNITS
from ..core.security import get_password_hash
from ..core.time import local_today, utcnow
from ..models import (
    CaregiverElderlyLink,
    CaregiverProfile,
    ElderlyProfile,
    EmergencyContact,
    EmergencyIncident,
    HealthVital,
    Medication,
    MedicationLog,
    PatientBaseline,
    User,
    WearableDevice,
)
from ..services import risk
from .session import SessionLocal

logger = logging.getLogger(__name__)

ELDERLY_PHONE = "+94771234567"
CAREGIVER_PHONE = "+94719876543"


def seed() -> None:
    db = SessionLocal()
    try:
        if db.query(User.id).filter(User.phone == ELDERLY_PHONE).first():
            logger.info("Demo data already present - skipping.")
            return

        now = utcnow()
        kamala = User(
            phone=ELDERLY_PHONE,
            email="kamala.perera@elderguard.lk",
            hashed_password=get_password_hash("password123"),
            full_name="Kamala Perera",
            role="elderly",
        )
        nimal = User(
            phone=CAREGIVER_PHONE,
            email="nimal.perera@gmail.com",
            hashed_password=get_password_hash("password123"),
            full_name="Nimal Perera",
            role="caregiver",
        )
        db.add_all([kamala, nimal])
        db.flush()

        elderly = ElderlyProfile(
            id="ELD-001",
            user_id=kamala.id,
            age=72,
            gender="Female",
            blood_group="O+",
            address="No. 42, Temple Road, Colombo 03",
            linking_code="EG-8829-KP",
            chronic_conditions=["Hypertension", "Type 2 Diabetes", "Mild Arthritis"],
            allergies=["Penicillin", "Sulfa Drugs"],
            primary_doctor="Dr. Anura Wijesinghe (General Hospital)",
            avatar_url="assets/images/avatar_kamala_perera.jpg",
        )
        caregiver = CaregiverProfile(
            id="CG-001",
            user_id=nimal.id,
            relationship_to_elder="Son & Primary Caregiver",
            avatar_url="assets/images/avatar_nimal_perera.jpg",
        )
        db.add_all([elderly, caregiver])
        db.flush()

        db.add_all([
            EmergencyContact(elderly_id=elderly.id, name="Nimal Perera", relationship="Son", phone=CAREGIVER_PHONE),
            CaregiverElderlyLink(caregiver_id=caregiver.id, elderly_id=elderly.id, status="active"),
            PatientBaseline(
                elderly_id=elderly.id,
                heart_rate_min=58,
                heart_rate_max=95,
                spo2_min=94,
                temperature_min=36.0,
                temperature_max=37.4,
                defined_by="Dr. Anura Wijesinghe",
                notes="Hypertensive patient on Amlodipine; resting HR typically 70-80.",
                updated_by_user_id=nimal.id,
            ),
        ])

        # Demo device; pairing a real ESP32 from the app replaces its BLE id.
        device = WearableDevice(
            elderly_id=elderly.id,
            device_name="ElderGuard Band (demo)",
            mac_address="DEMO-DEVICE",
            battery_level=92,
            connection_status="disconnected",
            firmware_version="demo",
            is_simulated=True,
        )
        db.add(device)
        db.flush()

        # 7 days of readings, 6 per day, so trends and anomaly detection have history
        pattern = {
            "heart_rate": [72, 75, 78, 71, 74, 76],
            "spo2": [98, 97, 98, 99, 98, 97],
            "temperature": [36.5, 36.6, 36.7, 36.6, 36.4, 36.6],
            "activity_level": [120, 340, 260, 90, 410, 60],
        }
        for day in range(7, -1, -1):
            for slot in range(6):
                measured = now - timedelta(days=day, hours=slot * 4)
                if measured > now:
                    continue
                for metric, values in pattern.items():
                    db.add(HealthVital(
                        elderly_id=elderly.id,
                        device_id=device.id,
                        metric_type=metric,
                        value=values[(slot + day) % len(values)],
                        unit=METRIC_UNITS[metric],
                        status="normal",
                        source="seed",
                        measured_at=measured,
                    ))

        meds = [
            ("MED-1", "Metformin 500mg", "1 Tablet", "Morning", time(8, 0), "After Breakfast"),
            ("MED-2", "Amlodipine 5mg", "1 Tablet", "Morning", time(8, 30), "With Water"),
            ("MED-3", "Calcium & Vit D3", "1 Capsule", "Afternoon", time(13, 0), "After Lunch"),
            ("MED-4", "Atorvastatin 10mg", "1 Tablet", "Evening", time(20, 30), "Before Sleep"),
        ]
        today = local_today()
        for med_id, name, dosage, period, at, instruction in meds:
            db.add(Medication(
                id=med_id, elderly_id=elderly.id, name=name, dosage=dosage,
                schedule_period=period, scheduled_time=at, instruction=instruction,
            ))
            db.flush()
            for day in range(1, 7):  # past week: all taken except one missed dose
                status = "missed" if (med_id == "MED-3" and day == 3) else "taken"
                db.add(MedicationLog(
                    medication_id=med_id, elderly_id=elderly.id,
                    scheduled_date=today - timedelta(days=day), scheduled_time=at,
                    status=status, confirmed_at=now - timedelta(days=day),
                ))

        db.add(EmergencyIncident(
            elderly_id=elderly.id,
            incident_type="fall_detected",
            title="Potential Fall Detected",
            description="Impact of 2.8G registered by the wearable.",
            impact_force_g=2.80,
            location_text="Living Room (Ground Floor)",
            severity="critical",
            status="false_alarm",
            triggered_at=now - timedelta(days=2),
            resolved_at=now - timedelta(days=2) + timedelta(minutes=1),
        ))
        db.flush()

        risk.evaluate(db, elderly.id)
        db.commit()
        logger.info("Demo data seeded. Elderly %s / caregiver %s (password123)", ELDERLY_PHONE, CAREGIVER_PHONE)
    except Exception:
        db.rollback()
        logger.exception("Seeding failed")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    seed()
//this