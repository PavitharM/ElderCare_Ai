# ElderGuard AI: Project Summary

Read this file first. It condenses `Proposal.pdf`, `SRS.pdf` (v1.0, 12 Oct 2026) and the current code, so you don't need to re-read the whole repository.

Last updated: 2026-10-31 (branch `dev1`).

---

## 1. Project goal

ElderGuard AI is an academic prototype (SE5104 Mini Project, Sabaragamuwa University of Sri Lanka; IoTrix 2.0 Track C) for **personalized monitoring and emergency assistance for elderly people who live alone**.

The data flow is:

1. An **ESP32 wearable** reads heart rate, SpO₂, temperature and motion, and detects falls.
2. It sends the data over **BLE** to a **dual-mode Flutter app** (Elderly Mode and Caregiver Mode).
3. The app relays the data to a **FastAPI + MySQL backend**, which:
   - stores the history,
   - runs an **explainable risk engine** that classifies the situation as **Normal / Warning / High Risk / Critical**,
   - **push-alerts linked caregivers** on Critical events or SOS.
4. A **tokenized QR code** on the elderly person's phone opens a **zero-login, read-only hospital web page** that prints as a one-page summary (Ctrl+P).

**Out of scope:** diagnosis, treatment, certified medical device, guaranteed fall detection, ambulance dispatch, hospital EMR integration, iOS as a core target.

### Team and module ownership

| Member | Module |
|---|---|
| V. Kathirsan (22CSE0401) | IoT wearable and BLE (`firmware/`) |
| S. Abisegan (22CSE0400) | Backend API and risk engine (`backend/`) |
| M. Pavithar (22CSE0393) | Flutter dual-mode app (`frontend/`) |
| R.M.P.B. Rajaguru / Parami (22CSE0370) | Hospital QR web dashboard (`backend/app/web/`) |

### Decisions agreed on 2026-10-31

- **Doctor-defined baselines (FR-27):** backend API only. A linked caregiver enters the values on the doctor's behalf. There is no doctor role or screen.
- **Push notifications:** a pluggable sender. It runs in simulated mode until `FCM_CREDENTIALS_FILE` is set in `.env`.
- **Hospital QR view:** a server-rendered HTML page served by FastAPI at `/qr/{token}`.
- **Wearable hardware:** ESP32 + MAX30102 + MPU6050 + DS18B20. It transmits periodically, and immediately on abnormal readings or falls, to save power.
- **BLE in the app:** real BLE (`flutter_blue_plus`, nonprofit/educational license) on Android. Web and Chrome builds use simulated devices.
- **UI:** the Flutter UI and design are frozen. Only logic behind the screens may change.
- **Direct emergency SMS:** the patient's phone texts caregivers and emergency contacts from its own SIM, in addition to the backend push. Triggers: a fall after the countdown, a manual SOS, and Critical vitals (10-minute cooldown). This works without internet. It extends Proposal Layer 4, so the documents should be updated to mention it.

---

## 2. Repository layout

```
ElderCare_Ai/
├── backend/                     FastAPI service
│   ├── app/
│   │   ├── main.py              App factory, CORS, /health
│   │   ├── core/                config, security (JWT/bcrypt), constants, time helpers
│   │   ├── db/                  Base, session, seed (python -m app.db.seed)
│   │   ├── models/              SQLAlchemy ORM
│   │   ├── schemas/             Pydantic request/response models
│   │   ├── api/deps.py          auth + caregiver-link access dependencies
│   │   ├── api/v1/router.py     mounts all endpoint modules
│   │   ├── api/v1/endpoints/    auth, elderly, caregiver, vitals, baselines, medications,
│   │   │                        devices, emergencies, notifications, triage, risk
│   │   ├── services/            business logic: access, accounts, vitals, telemetry, risk,
│   │   │                        medication, emergency, triage, notifications/
│   │   ├── ai/risk_engine.py    pure risk logic (no DB access)
│   │   └── web/                 hospital QR page (Jinja2 templates + print CSS)
│   ├── alembic/                 migrations (930b… initial, b41c… SRS alignment)
│   ├── tests/
│   ├── requirements.txt, requirements-dev.txt, .env.example, run.py
├── frontend/                    Flutter app (lib/core, models, screens, services, state, widgets)
│   └── lib/services/ble/        BLE protocol + WearableBleService
├── firmware/esp32-wearable/     PlatformIO project (src/, include/config.h, README.md)
└── docs/SUMMARY.md              this file
```

---

## 3. Functional requirements (SRS §3) and where each is implemented

| # | Requirement | Status / location |
|---|---|---|
| FR-01 | Elderly and caregiver authentication | Done. `POST /auth/login`, `/auth/register/*`; JWT |
| FR-02 | Restrict functions by role/mode | Done. `api/deps.py`, `services/access.py` (caregiver must have an active link plus permission) |
| FR-03 | Elderly profile management | Done. `GET/PUT /elderly/me/profile` |
| FR-04 | Tokenized patient QR | Done. `POST /triage/generate-token` returns `qr_url`; Flutter QR screen encodes it |
| FR-05 | Wearable registration | Done. `POST /devices/pair` (one wearable per profile; BLE remote id) |
| FR-06 | Sensor acquisition and validation | Done. Firmware; backend plausibility bounds (`core/constants.py`) |
| FR-07 | BLE communication, detect failures | Done. Firmware `ble_link.cpp`; Flutter `wearable_ble_service.dart` (auto-reconnect, status reported to backend) |
| FR-08 | Live dashboard, stale-data indicator | Done. `GET /vitals/latest` (`is_stale`, `measured_at`) |
| FR-09 | Store readings with timestamp and device | Done. `health_vitals.device_id`, `measured_at` |
| FR-10 | Daily/weekly/monthly trends | Done. `GET /vitals/trends?days=1..31` |
| FR-11 | Anomaly detection | Done. z-score of the latest value vs. the patient's 7-day history; stored in `risk_assessments.anomalies` |
| FR-12 | Personalized risk assessment | Done. `ai/risk_engine.py`, `services/risk.py` |
| FR-13 | Normal / Warning / High Risk / Critical | Done. Stored per assessment |
| FR-14 | Fall detection with confirmation before escalation | Done. Firmware 3-phase detector; backend countdown (`FALL_CONFIRM_SECONDS`), `/escalate`, `/cancel` |
| FR-15 | Configure medications (name, dose, time, frequency, instructions) | Done. `POST/PUT/DELETE /medications` (daily or weekly) |
| FR-16 | Medication reminders | Partial. Schedule is served; on-device local notifications are not implemented yet (needs a Flutter notification package) |
| FR-17 | Taken / Missed / Pending | Done. `confirm-dose?status=`; pending doses auto-marked Missed after a grace period |
| FR-18 | Adherence analysis (no causation claims) | Done. `GET /medications/adherence`; used as context by the risk engine |
| FR-19 | SOS and emergency events trigger the workflow | Done. `POST /emergencies/sos`; Critical risk raises a `critical_vital` incident |
| FR-20 | Elderly alerts and acknowledgement | Partial. Fall countdown screen; push to the elderly user not implemented |
| FR-21 | Push to linked caregivers | Done. `services/notifications` (FCM or simulated); delivery status in `incident_notifications`. Also a direct SMS from the patient's phone (`frontend/lib/services/emergency_sms_service.dart` + `MainActivity.kt`, Android `SEND_SMS`) |
| FR-22 | Caregiver review of assigned users | Done. Every read endpoint accepts `?elderly_id=` for linked caregivers; `GET /caregiver/portal` |
| FR-23 | Zero-login QR access, read-only, scoped | Done. `GET /qr/{token}` (HTML), `GET /triage/summary/{token}` (JSON); access count and last access logged |
| FR-24 | One-page printable summary | Done. `web/templates/base.html` `@media print`, A4 |
| FR-25 | Documented REST API | Done. Swagger at `/docs` |
| FR-26 | Audit / event records | Partial. Incidents, notifications, medication logs, risk history and QR access are stored; there is no generic auth audit log |
| FR-27 | Doctor-defined baselines | Done. `GET/PUT /baselines` (PUT by a linked caregiver only) |
| FR-28 | Reject invalid or stale data | Done. Plausibility bounds; stale flag; unpaired device rejected (403) |

**Non-functional requirements (§6), as implemented:**
- **NFR-05 security:** bcrypt, JWT, link-based authorization, HTTPS required in release, production refuses the default secret.
- **NFR-06 privacy:** the QR exposes only the summary fields.
- **NFR-07 maintainability:** layered architecture.
- **NFR-09 data integrity:** soft-deleted medications keep their history.
- **NFR-12 auditability:** see FR-26.
- **NFR-14 resource efficiency:** firmware transmits only when needed.
- **NFR-15 safety:** a disclaimer is shown on every risk result and on the QR page.

---

## 4. IoT device and data

**Hardware:**

| Part | Measures | Connection |
|---|---|---|
| ESP32 DevKit | – | – |
| MAX30102 | Heart rate, SpO₂ | I2C SDA 21 / SCL 22 |
| MPU6050 | Motion, activity, falls | I2C, shared bus |
| DS18B20 | Skin temperature | GPIO 4, 4.7 kΩ pull-up |
| LiPo + 100k/100k divider | Battery level | GPIO 34 |

### BLE GATT
- **Advertised name:** `ElderGuard-XXXX`
- **Service:** `6e1f0001-8b3a-4c2e-9d5a-6f1e2d3c4b5a`
  - **Telemetry** `6e1f0002-…`: READ and NOTIFY, UTF-8 JSON
  - **Control** `6e1f0003-…`: WRITE, `SYNC` or `PING`
- **Battery Service:** `0x180F` / `0x2A19`
- **Firmware revision:** `0x180A` / `0x2A26`
- **MTU:** 247 (Flutter requests 512 on Android)

### Packet format
Fields are omitted when a sensor has no valid reading.

```json
{"v":1,"seq":12,"t":"abnormal","hr":118,"spo2":97,"temp":36.4,"act":85,"bat":91,"fw":"1.0.0","fall_g":2.8}
```

| Key | Meaning | Unit |
|---|---|---|
| `t` | Trigger: `periodic` \| `abnormal` \| `fall` \| `sync` | – |
| `hr` | Heart rate | BPM |
| `spo2` | Blood oxygen | % |
| `temp` | Temperature (skin + `TEMP_OFFSET_C`) | °C |
| `act` | Mean dynamic acceleration over 60 s | milli-g |
| `bat` | Battery | % |
| `fall_g` | Peak impact, only in `fall` packets | G |

### Transmission policy (`include/config.h`)

| Trigger | When |
|---|---|
| `periodic` | Every 60 s |
| `abnormal` | Immediately when a value leaves the device-side band (HR <50 or >115, SpO₂ <92, temperature <35 or >37.8) or jumps sharply (ΔHR ≥15, ΔSpO₂ ≥3, ΔTemp ≥0.6). At most once every 15 s. |
| `fall` | Immediately: free fall (<0.4 G), then an impact (>2.5 G) within 1 s, then 2 s of stillness |
| `sync` | When the phone connects or writes `SYNC` |

While the phone is disconnected, up to 8 `fall`/`abnormal` packets are queued and flushed on reconnect.

### End-to-end flow
1. The phone receives a packet.
2. It sends `POST /vitals/telemetry`.
3. The backend validates and stores the readings, creates a fall incident if needed, re-runs the risk engine, and alerts caregivers if the result is Critical.
4. For a `fall` packet, the app opens the 25 s countdown screen:
   - user taps cancel → `POST /emergencies/{id}/cancel`
   - countdown ends or user taps "send now" → `POST /emergencies/{id}/escalate`
   - if the phone goes offline, the backend escalates automatically when the countdown expires (checked on the next caregiver or emergency read).

### Emergency alert channels
Both channels run in parallel for a fall after the countdown, a manual SOS, and Critical vitals:

| Channel | Path | Works without internet? |
|---|---|---|
| Direct SMS | Patient's SIM → caregivers and emergency contacts | Yes |
| Push | Backend → FCM → linked caregivers' phones | No |

- **SMS recipients** come from `GET /elderly/me/alert-contacts`, fetched after login. If the backend can't be reached, the profile's emergency contact is used.
- **Critical vitals SMS** fires when the backend returns `risk_level: critical`, **or** when the phone's own check finds a reading past the hard critical limits (HR <40 or >130, SpO₂ <90, temperature <35 or ≥39). This second check covers the offline case.
- **Cooldown:** at most one critical-vitals SMS every 10 minutes, and none within 10 minutes of a fall or SOS SMS.
- **Android permission:** the app asks for `SEND_SMS` at startup.
- **Cost:** the SMS is charged to the patient's SIM.

### Risk engine rules (`backend/app/ai/risk_engine.py`)
- **Vital status:** each vital is compared with the personal baseline (or defaults: HR 60–100, SpO₂ ≥95, temperature 36.0–37.5) and with hard critical limits (HR <40 or >130, SpO₂ <90, temperature <35 or ≥39).
- **Anomaly:** |z| ≥ 3 against the patient's last 7 days (needs at least 10 points).
- **Critical:** any critical vital, OR an active SOS, OR a fall within the last hour together with an abnormal vital or no movement.
- **High Risk:** a confirmed fall within 24 h, OR 2 or more warning vitals, OR a warning vital plus an anomaly.
- **Warning:** one warning vital, OR an anomaly, OR adherence below 75%, OR any confirmed fall in the last 7 days.
- **Normal:** none of the above.
- **Stale data:** a vital older than `VITAL_STALE_AFTER_MINUTES` (15) is ignored, and the staleness is reported as a factor.

---

## 5. API endpoints

**Basics:**
- **Base URL:** `/api/v1`
- **Auth:** `Authorization: Bearer <JWT>`. Get a token from `POST /auth/login` with `{"username": phone-or-email, "password"}`.
- **Caregivers** add `?elderly_id=<id>` on patient endpoints. It can be omitted when the caregiver has exactly one linked patient. Unlinked patients return 403.

### Auth
- `POST /auth/login`: returns `{access_token, token_type, role, user_id, full_name, linking_code}`
- `POST /auth/register/elderly`:
  ```json
  {"full_name", "phone", "password" (≥6), "age", "gender", "blood_group", "address",
   "chronic_conditions": [], "allergies": [], "primary_doctor",
   "emergency_contact_name", "emergency_contact_relation", "emergency_contact_phone"}
  ```
- `POST /auth/register/caregiver`: `{full_name, email?, phone, password, relationship_to_elder, elderly_linking_code?}`
- `GET /auth/me`

### Elderly user (role: elderly)
- `GET /elderly/me/profile` and `PUT /elderly/me/profile`
- `GET /elderly/me/dashboard`: `{patient_name, age, linking_code, vitals{metric:{value, unit, status, measured_at, is_stale}}, wearable{name, connected, battery, last_seen}, risk_assessment{level, label, factors, disclaimer}, next_medication}`
- `GET /elderly/me/history`: timeline of emergencies and taken/missed doses
- `GET /elderly/me/alert-contacts`: `[{name, phone, relationship, source: caregiver|emergency_contact}]`, de-duplicated by phone. These are the direct SMS recipients.

### Caregiver
- `GET /caregiver/portal`: `{caregiver_name, relationship, linked_elders[…], active_alerts[…]}`
- `POST /caregiver/link-by-code`: `{"linking_code": "EG-8829-KP"}`

### Vitals and telemetry
- `GET /vitals/latest`: `{heart_rate|spo2|temperature: {label, value, unit, status_text, status, normal_range, history_7_days[], measured_at, is_stale}, last_updated}`
- `GET /vitals/trends?days=7`: per metric (including `activity_level`): `{label, unit, average, min, max, daily_average[], data_points[{value, measured_at}]}`
- `POST /vitals/telemetry` (elderly):
  - request: `{"device_id", "trigger": "periodic|abnormal|fall|sync", "sequence"?, "battery_level"?, "readings": [{"metric_type": "heart_rate|spo2|temperature|activity_level", "value", "measured_at"?}], "fall"?: {"impact_g"}}`
  - response: `{accepted, rejected[], risk_level, incident_id}`
- `POST /vitals/ingest`: `{metric_type, value, secondary_value?, unit?, source?, measured_at?}` (single manual reading)

### Baselines (FR-27)
- `GET /baselines`: `{elderly_id, heart_rate_min, heart_rate_max, spo2_min, temperature_min, temperature_max, notes, defined_by, is_default, updated_at}`
- `PUT /baselines?elderly_id=` (linked caregiver only): same fields

### Medications
- `GET /medications/my-schedule`: today's doses `[{id, name, dosage, schedule_period, time "08:00 AM", instruction, is_taken, status, frequency}]`
- `POST /medications/{id}/confirm-dose?taken=true|false[&status=taken|missed|pending|skipped]`
- `GET /medications/adherence`: `{adherence_percentage, streak_days, taken_doses_this_week, total_doses_this_week, missed_doses_this_week}`
- `POST /medications`: `{name, dosage, schedule_period: Morning|Afternoon|Evening|Night, scheduled_time "HH:MM", frequency: daily|weekly, days_of_week?[0-6], instruction?}`
- `PUT /medications/{id}` (partial update) and `DELETE /medications/{id}` (soft delete)

### Devices
- `GET /devices/my-device`
- `POST /devices/pair`: `{device_name, mac_address (BLE remote id), firmware_version?, battery_level?}`
- `PUT /devices/my-device/status`: `{connection_status: connected|disconnected|syncing, battery_level?}`

### Emergencies
Responses use `EmergencyIncidentOut`: `{id, incident_type, title, description, impact_force_g, location_text, severity, status: active_countdown|dispatched|resolved|false_alarm, escalate_at, triggered_at, resolved_at, notifications[{contact_name, channel, delivery_status, status_message}]}`

- `POST /emergencies/fall-detected`: `{title?, description?, impact_force_g?, location_text?, latitude?, longitude?}`; starts the countdown
- `POST /emergencies/sos`: optional `{location_text, latitude, longitude}`; dispatches immediately
- `POST /emergencies/{id}/escalate`, `/cancel`, `/resolve`
- `GET /emergencies/{id}/status`
- `GET /emergencies/logs`

### Notifications
- `POST /notifications/device-token` and `DELETE /notifications/device-token`: `{token, platform: android|ios|web}`

### Hospital QR
- `POST /triage/generate-token` (elderly): returns `{qr_token, qr_url, expires_at}`. Revokes earlier tokens; TTL is `QR_TOKEN_TTL_HOURS`.
- `POST /triage/revoke`
- `GET /triage/summary/{token}` (no auth): `{patient_name, age, gender, blood_group, allergies, chronic_conditions, primary_doctor, emergency_contacts, latest_vitals{metric:{value, unit, status, measured_at}}, vitals_24h{metric:{min, max, avg}}, risk_level, risk_label, active_medications[], generated_at, expires_at}`
- `GET /qr/{token}` (no auth, outside `/api/v1`): printable HTML page. Invalid/revoked/expired tokens return 404/403/410 with no patient data.

### Risk
- `GET /ai/risk-assessment/latest` and `POST /ai/risk-assessment/evaluate`: `{risk_level, status_label, confidence_score, vital_score, adherence_score|null, fall_risk_score, contributing_factors[], anomalies[], disclaimer, calculated_at}`

### System
- `GET /health`: returns 200 when the DB is connected, otherwise 503 (`database: unavailable`)
- `GET /docs`: Swagger UI

---

## 6. Configuration (`backend/.env`, see `.env.example`)

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | MySQL connection string |
| `SECRET_KEY` | JWT signing key. Must be changed in production. |
| `CORS_ORIGINS` | Allowed browser origins |
| `PUBLIC_BASE_URL` | Address encoded in the QR code. Use a LAN IP so clinic devices can reach it. |
| `TIMEZONE` | Medication schedule timezone (default `Asia/Colombo`) |
| `QR_TOKEN_TTL_HOURS` | QR token lifetime |
| `VITAL_STALE_AFTER_MINUTES` | When a reading counts as stale |
| `FALL_CONFIRM_SECONDS` | Fall countdown length. Must match the Flutter countdown (25 s). |
| `MEDICATION_MISSED_GRACE_MINUTES` | Grace period before a pending dose becomes Missed |
| `FCM_CREDENTIALS_FILE` | Firebase key for real push (blank = simulated) |

For the Flutter app on a physical phone:

```bash
flutter run --dart-define=API_BASE_URL=http://<PC-LAN-IP>:8000/api/v1
```

**Demo accounts** (from `python -m app.db.seed`):
- Elderly: `+94771234567` / `password123`
- Caregiver: `+94719876543` or `nimal.perera@gmail.com` / `password123`
- Linking code: `EG-8829-KP`

---

## 7. Known gaps / next steps
1. **FR-16:** local medication reminder notifications on the phone (e.g. `flutter_local_notifications`).
2. **FR-21:** Firebase client setup in Flutter (`firebase_messaging` + `google-services.json`), then call `POST /notifications/device-token` after login.
3. **Hard-coded demo login:** the Flutter app logs in automatically as the demo elderly user (`MockAppState.initBackendSync`). Real login and registration screens still need to call the auth endpoints.
4. **FR-26:** a generic audit log for authentication events.
5. **Production deployment:** HTTPS reverse proxy, strong `SECRET_KEY`, restricted `CORS_ORIGINS`.
