import uuid
from datetime import datetime, timezone, timedelta, date, time
from app.core.database import SessionLocal
from app.core.security import get_password_hash
from app.models.user import User
from app.models.elderly import ElderlyProfile, EmergencyContact, HospitalQRToken
from app.models.caregiver import CaregiverProfile, CaregiverElderlyLink
from app.models.vitals import WearableDevice, HealthVital
from app.models.medication import Medication, MedicationLog
from app.models.emergency import EmergencyIncident, IncidentNotification
from app.models.ai_risk import RiskAssessment

def seed():
    db = SessionLocal()
    try:
        # Check if already seeded
        existing_user = db.query(User).filter(User.phone == "+94771234567").first()
        if existing_user:
            print("Data already seeded. Skipping.")
            return

        print("Seeding initial ElderGuard AI data...")

        # 1. Create Elderly User (Kamala Perera)
        kamala_user = User(
            id=str(uuid.uuid4()),
            phone="+94771234567",
            email="kamala.perera@elderguard.lk",
            hashed_password=get_password_hash("password123"),
            full_name="Kamala Perera",
            role="elderly",
            is_active=True,
        )
        db.add(kamala_user)
        db.flush()

        # 2. Elderly Profile
        elderly_profile = ElderlyProfile(
            id="ELD-001",
            user_id=kamala_user.id,
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
        db.add(elderly_profile)
        db.flush()

        # 3. Emergency Contact
        contact1 = EmergencyContact(
            id=str(uuid.uuid4()),
            elderly_id=elderly_profile.id,
            name="Nimal Perera",
            relationship="Son",
            phone="+94719876543",
            priority_order=1,
        )
        db.add(contact1)

        # 4. Create Caregiver User (Nimal Perera)
        nimal_user = User(
            id=str(uuid.uuid4()),
            phone="+94719876543",
            email="nimal.perera@gmail.com",
            hashed_password=get_password_hash("password123"),
            full_name="Nimal Perera",
            role="caregiver",
            is_active=True,
        )
        db.add(nimal_user)
        db.flush()

        # 5. Caregiver Profile
        caregiver_profile = CaregiverProfile(
            id="CG-001",
            user_id=nimal_user.id,
            relationship_to_elder="Son & Primary Caregiver",
            notification_preferences={"sms": True, "push": True, "call": True},
            avatar_url="assets/images/avatar_nimal_perera.jpg",
        )
        db.add(caregiver_profile)
        db.flush()

        # 6. Link Caregiver to Elderly
        link = CaregiverElderlyLink(
            id=str(uuid.uuid4()),
            caregiver_id=caregiver_profile.id,
            elderly_id=elderly_profile.id,
            status="active",
            permissions={"can_view_vitals": True, "can_manage_meds": True, "receive_alerts": True},
        )
        db.add(link)

        # 7. Wearable Device
        wearable = WearableDevice(
            id="DEV-8492",
            elderly_id=elderly_profile.id,
            device_name="ElderGuard Band V2 #8492",
            mac_address="C4:72:8F:90:3B:12",
            battery_level=92,
            connection_status="connected",
            firmware_version="v2.1.4",
            is_simulated=True,
        )
        db.add(wearable)

        # 8. Health Vitals (Current & 7-Day History)
        now = datetime.now(timezone.utc)
        vitals_data = [
            ("heart_rate", 74.0, "BPM", "normal", [72.0, 75.0, 78.0, 71.0, 74.0, 76.0, 74.0]),
            ("spo2", 98.0, "%", "optimal", [98.0, 97.0, 98.0, 99.0, 98.0, 98.0, 98.0]),
            ("temperature", 36.6, "°C", "optimal", [36.5, 36.6, 36.7, 36.6, 36.4, 36.6, 36.6]),
        ]
        for metric, current_val, unit, status, history in vitals_data:
            # Store 7-day points
            for i, hist_val in enumerate(history):
                measured_time = now - timedelta(days=(6 - i))
                db.add(HealthVital(
                    id=str(uuid.uuid4()),
                    elderly_id=elderly_profile.id,
                    metric_type=metric,
                    value=hist_val,
                    unit=unit,
                    status=status,
                    source="wearable_ble",
                    measured_at=measured_time,
                ))

        # 9. Medications
        meds = [
            ("MED-1", "Metformin 500mg", "1 Tablet", "Morning", time(8, 0), "After Breakfast", True),
            ("MED-2", "Amlodipine 5mg", "1 Tablet", "Morning", time(8, 30), "With Water", True),
            ("MED-3", "Calcium & Vit D3", "1 Capsule", "Afternoon", time(13, 0), "After Lunch", False),
            ("MED-4", "Atorvastatin 10mg", "1 Tablet", "Evening", time(20, 30), "Before Sleep", False),
        ]
        today = date.today()
        for med_id, name, dosage, period, sched_time, instruction, taken in meds:
            med = Medication(
                id=med_id,
                elderly_id=elderly_profile.id,
                name=name,
                dosage=dosage,
                schedule_period=period,
                scheduled_time=sched_time,
                instruction=instruction,
                is_active=True,
            )
            db.add(med)
            db.flush()

            # Today's log entry
            log = MedicationLog(
                id=str(uuid.uuid4()),
                medication_id=med.id,
                elderly_id=elderly_profile.id,
                scheduled_date=today,
                scheduled_time=sched_time,
                status="taken" if taken else "pending",
                confirmed_at=now if taken else None,
            )
            db.add(log)

        # 10. Emergency Incidents
        incident1 = EmergencyIncident(
            id="EVT-101",
            elderly_id=elderly_profile.id,
            incident_type="fall_detected",
            title="Potential Fall Detected",
            description="Sudden deceleration 2.8G registered by wearable in Living Room.",
            impact_force_g=2.80,
            location_text="Living Room (Ground Floor)",
            severity="critical",
            status="resolved",
            triggered_at=now - timedelta(minutes=42),
            resolved_at=now - timedelta(minutes=35),
        )
        db.add(incident1)
        db.flush()

        notif1 = IncidentNotification(
            id=str(uuid.uuid4()),
            incident_id=incident1.id,
            contact_name="Nimal Perera",
            contact_phone="+94719876543",
            channel="sms",
            delivery_status="simulated_sent",
            status_message="Alert SMS delivered to son Nimal Perera (+94719876543)",
            dispatched_at=now - timedelta(minutes=41),
        )
        db.add(notif1)

        # 11. AI Risk Assessment
        risk = RiskAssessment(
            id=str(uuid.uuid4()),
            elderly_id=elderly_profile.id,
            risk_level="low",
            status_label="Low Risk - Stable",
            confidence_score=0.920,
            vital_score=95.0,
            adherence_score=94.0,
            fall_risk_score=10.0,
            contributing_factors=[
                "SpO2 saturation optimal at 98%",
                "Resting heart rate steady at 74 BPM within normal window",
                "Medication adherence at 94% with active 14-day streak",
                "Wearable telemetry synchronized 2 minutes ago",
            ],
            disclaimer="Algorithmic risk observation only; not a clinical medical diagnosis.",
            calculated_at=now,
        )
        db.add(risk)

        # 12. Hospital QR Token
        qr_token = HospitalQRToken(
            id=str(uuid.uuid4()),
            elderly_id=elderly_profile.id,
            token="EG-EMERGENCY-QR-TOKEN-KP8829-VALID24H",
            expires_at=now + timedelta(hours=24),
            is_revoked=False,
            access_count=0,
        )
        db.add(qr_token)

        db.commit()
        print("Database successfully seeded with realistic ElderGuard AI clinical data!")
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed()
