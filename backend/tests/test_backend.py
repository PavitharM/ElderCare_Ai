import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_healthcheck():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "ElderGuard" in data["service"]

def test_login_elderly():
    response = client.post("/api/v1/auth/login", json={
        "username": "+94771234567",
        "password": "password123",
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["role"] == "elderly"
    assert data["full_name"] == "Kamala Perera"
    assert data["linking_code"] == "EG-8829-KP"

def test_login_caregiver():
    response = client.post("/api/v1/auth/login", json={
        "username": "+94719876543",
        "password": "password123",
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["role"] == "caregiver"
    assert data["full_name"] == "Nimal Perera"

def test_invalid_login():
    response = client.post("/api/v1/auth/login", json={
        "username": "+94771234567",
        "password": "wrongpassword",
    })
    assert response.status_code == 401

def test_elderly_profile_and_dashboard():
    # Login as elderly
    login_res = client.post("/api/v1/auth/login", json={
        "username": "+94771234567",
        "password": "password123",
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Profile
    prof_res = client.get("/api/v1/elderly/me/profile", headers=headers)
    assert prof_res.status_code == 200
    prof = prof_res.json()
    assert prof["name"] == "Kamala Perera"
    assert prof["linking_code"] == "EG-8829-KP"
    assert "Hypertension" in prof["chronic_conditions"]
    assert len(prof["emergency_contacts"]) > 0

    # Dashboard
    dash_res = client.get("/api/v1/elderly/me/dashboard", headers=headers)
    assert dash_res.status_code == 200
    dash = dash_res.json()
    assert dash["patient_name"] == "Kamala Perera"
    assert "heart_rate" in dash["vitals"]
    assert "risk_assessment" in dash

def test_vitals_telemetry():
    login_res = client.post("/api/v1/auth/login", json={
        "username": "+94771234567",
        "password": "password123",
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    vitals_res = client.get("/api/v1/vitals/latest", headers=headers)
    assert vitals_res.status_code == 200
    data = vitals_res.json()
    assert "heart_rate" in data
    assert "spo2" in data
    assert "temperature" in data
    assert len(data["heart_rate"]["history_7_days"]) > 0

def test_medication_schedule_and_confirmation():
    login_res = client.post("/api/v1/auth/login", json={
        "username": "+94771234567",
        "password": "password123",
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Get schedule
    sched_res = client.get("/api/v1/medications/my-schedule", headers=headers)
    assert sched_res.status_code == 200
    meds = sched_res.json()
    assert len(meds) > 0
    first_med = meds[0]

    # Confirm dose
    conf_res = client.post(f"/api/v1/medications/{first_med['id']}/confirm-dose?taken=true", headers=headers)
    assert conf_res.status_code == 200
    assert conf_res.json()["is_taken"] is True

    # Adherence
    adh_res = client.get("/api/v1/medications/adherence", headers=headers)
    assert adh_res.status_code == 200
    assert adh_res.json()["adherence_percentage"] >= 0

def test_emergency_incident_and_false_alarm():
    login_res = client.post("/api/v1/auth/login", json={
        "username": "+94771234567",
        "password": "password123",
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Trigger fall
    fall_res = client.post("/api/v1/emergencies/fall-detected", json={
        "title": "Deceleration 2.8G registered",
        "impact_force_g": 2.8,
        "location_text": "Living Room",
    }, headers=headers)
    assert fall_res.status_code == 200
    incident = fall_res.json()
    assert incident["status"] == "active_countdown"
    incident_id = incident["id"]

    # Cancel false alarm
    cancel_res = client.post(f"/api/v1/emergencies/{incident_id}/cancel", headers=headers)
    assert cancel_res.status_code == 200
    assert cancel_res.json()["status"] == "success"

    # Verify status updated
    status_res = client.get(f"/api/v1/emergencies/{incident_id}/status", headers=headers)
    assert status_res.status_code == 200
    assert status_res.json()["status"] == "false_alarm"

def test_triage_qr_token():
    login_res = client.post("/api/v1/auth/login", json={
        "username": "+94771234567",
        "password": "password123",
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Generate QR token
    gen_res = client.post("/api/v1/triage/generate-token", headers=headers)
    assert gen_res.status_code == 200
    qr_token = gen_res.json()["qr_token"]

    # Triage summary access
    summary_res = client.get(f"/api/v1/triage/summary/{qr_token}")
    assert summary_res.status_code == 200
    summary = summary_res.json()
    assert summary["patient_name"] == "Kamala Perera"
    assert summary["blood_group"] == "O+"
    assert "Penicillin" in summary["allergies"]

def test_ai_risk_assessment():
    login_res = client.post("/api/v1/auth/login", json={
        "username": "+94771234567",
        "password": "password123",
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    risk_res = client.get("/api/v1/ai/risk-assessment/latest", headers=headers)
    assert risk_res.status_code == 200
    risk = risk_res.json()
    assert risk["risk_level"] in ["low", "moderate", "high"]
    assert len(risk["contributing_factors"]) > 0
    assert "not a clinical medical diagnosis" in risk["disclaimer"]

def test_caregiver_portal():
    login_res = client.post("/api/v1/auth/login", json={
        "username": "+94719876543",
        "password": "password123",
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    portal_res = client.get("/api/v1/caregiver/portal", headers=headers)
    assert portal_res.status_code == 200
    portal = portal_res.json()
    assert portal["caregiver_name"] == "Nimal Perera"
    assert len(portal["linked_elders"]) > 0
    first_elder = portal["linked_elders"][0]
    assert first_elder["name"] == "Kamala Perera"
    assert first_elder["linking_code"] == "EG-8829-KP"
