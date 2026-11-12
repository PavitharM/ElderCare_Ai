<<<<<<< HEAD
# ElderCare_Ai
=======
# ElderGuard AI

An AI-powered, IoT-based system for personalized elderly health monitoring and emergency assistance. It has four parts:
- an ESP32 wearable
- a dual-mode Flutter app (Elderly Mode and Caregiver Mode)
- a FastAPI + MySQL backend with a risk engine
- a zero-login hospital QR summary page

> **New to the project? Read [docs/SUMMARY.md](docs/SUMMARY.md) first.** It covers the requirements, the IoT protocol, every API endpoint and the data formats.

```
ElderCare_Ai/
├── backend/                 FastAPI + MySQL (API, risk engine, hospital QR page)
├── frontend/                Flutter mobile app
├── firmware/esp32-wearable/ ESP32 firmware (PlatformIO)
└── docs/SUMMARY.md          project summary
```

## Prerequisites

| Tool | Version |
|---|---|
| Python | 3.11+ |
| MySQL | 8.0+ |
| Flutter | 3.24+ |
| PlatformIO | For the firmware only |

## 1. Backend

Run these from the `backend/` folder. The commands below are for Windows PowerShell (macOS/Linux equivalents are in comments).

```bash
python -m venv venv
venv\Scripts\activate              # macOS/Linux: source venv/bin/activate
pip install -r requirements-dev.txt
copy .env.example .env             # macOS/Linux: cp .env.example .env
```

Then:
1. Edit `.env`: set `DATABASE_URL` and `SECRET_KEY`.
2. Create the database in MySQL: `CREATE DATABASE elderguard_db;`
3. Run the migrations, load the demo data, and start the server:

```bash
alembic upgrade head               # create/upgrade tables
python -m app.db.seed              # demo data (safe to re-run)
python run.py                      # http://localhost:8000/docs
```

Optional: `pytest` runs the tests against the seeded database.

## 2. Flutter app

Run these from the `frontend/` folder.

```bash
flutter pub get
flutter run -d chrome              # UI testing; wearable is simulated on web
flutter run                        # Android phone: real BLE wearable
```

On a **physical Android phone**, point the app at your PC's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
```

Also set `PUBLIC_BASE_URL=http://192.168.1.20:8000` in `backend/.env`, so the hospital QR code opens on other devices.

## 3. Wearable firmware

See [firmware/esp32-wearable/README.md](firmware/esp32-wearable/README.md) for wiring and flashing (`pio run -t upload`).

## Test accounts

| Role | Login | Password |
|---|---|---|
| Elderly (Kamala Perera) | `+94771234567` | `password123` |
| Caregiver (Nimal Perera) | `+94719876543` or `nimal.perera@gmail.com` | `password123` |

Linking code: `EG-8829-KP`

## Disclaimer

ElderGuard AI is an academic decision-support prototype. It is not a medical device and does not provide diagnosis.
>>>>>>> origin/dev
