# ElderGuard AI — AI-Powered Elderly Health & Emergency Assistance System

ElderGuard AI is an AI-powered IoT-based personalized elderly health monitoring and emergency assistance system.

---

## Architecture Overview

```
ElderCare/
├── backend/                       # Python FastAPI Backend
│   ├── app/
│   │   ├── api/v1/                # REST API Routers (auth, elderly, caregiver, vitals, etc.)
│   │   ├── core/                  # Security, Database session, Config, Seed data
│   │   ├── models/                # SQLAlchemy 2.0 ORM Models
│   │   ├── schemas/               # Pydantic v2 validation schemas
│   │   ├── ai/                    # AI Risk Assessment Observation Engine
│   │   └── main.py                # FastAPI Application Entrypoint
│   ├── alembic/                   # Alembic database migrations
│   ├── tests/                     # Automated pytest suite
│   ├── .env.example               # Environment variable template
│   ├── requirements.txt           # Python backend dependencies
│   └── run.py                     # Uvicorn launcher
├── lib/                           # Flutter Frontend (26 Stitch-matched UI screens)
│   ├── core/                      # Clinical Empathy design system, theme, typography
│   ├── models/                    # Frontend Dart data models
│   ├── screens/                   # Onboarding, Elderly, Caregiver, Wearable, Emergency flows
│   ├── services/                  # ApiClient & ElderGuardApiService
│   ├── state/                     # AppState with live FastAPI & fallback sync
│   └── widgets/                   # Clinical buttons, cards, pulse radar, nav bars
└── assets/images/                 # Original illustrations, avatars, and icons
```

---

## 1. Prerequisites
- **Python**: 3.9+
- **MySQL**: 8.0+ (running locally on port 3306)
- **Flutter**: 3.24+ / 3.47+

---

## 2. Backend Setup & Run

### A. Start MySQL Service
```bash
brew services start mysql
```

### B. Setup Python Virtual Environment & Install Dependencies
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### C. Run Database Migrations (Alembic)
```bash
source venv/bin/activate
alembic upgrade head
```

### D. Seed Initial Clinical Test Data
```bash
source venv/bin/activate
python -m app.core.seed_data
```

### E. Run Automated Backend Tests
```bash
source venv/bin/activate
PYTHONPATH=. pytest tests/test_backend.py -v
```

### F. Start the FastAPI Server
```bash
source venv/bin/activate
python run.py
# Or: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Interactive Swagger API documentation: **http://localhost:8000/docs**

---

## 3. Frontend Setup & Run (Flutter)

### In Chrome / Web:
```bash
flutter run -d chrome
```
*(Or view production build at `http://localhost:8080`)*

### On Android Emulator:
```bash
flutter run -d emulator-5554
```

---

## 4. Test Accounts & Linking Code

- **Elderly Patient (Kamala Perera)**:
  - Phone: `+94771234567`
  - Password: `password123`
  - Linking Code: `EG-8829-KP`
- **Primary Caregiver (Nimal Perera)**:
  - Phone: `+94719876543`
  - Email: `nimal.perera@gmail.com`
  - Password: `password123`
