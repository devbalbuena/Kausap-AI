# Kausap AI 💚

**Your Mental Wellness Companion.** 
Kausap AI is a comprehensive mental health platform offering a chatbot, mood tracking, and professional counseling integration, designed specifically for users and mental health professionals.

## 📱 Project Structure

This repository is a monorepo containing both the Flutter frontend app and the FastAPI backend service.

- `/mobile` - **Frontend**: A cross-platform Flutter application supporting iOS, Android, and Web.
- `/backend` - **Backend**: A FastAPI server connected to a Neon PostgreSQL database, utilizing SQLModel for ORM and Pydantic for validation.

## ✨ Features (Completed & In-Progress)

- **Role-based Access**: Dedicated experiences for "Clients" (Patients) and "Professionals" (Counselors/Psychologists).
- **Secure Authentication**: JWT-based authentication system with secure token storage.
- **Mental Health Chatbot**: AI-driven conversation sessions with risk-flagging capabilities.
- **Mood Tracking**: Track and monitor user mood entries over time.
- **Doctor Referrals**: Manage referrals to health professionals.
- **Session Booking**: Clients can book, view upcoming, and review past 1-on-1 therapy sessions with conflict checking.
- **Unified Design System**: Built with Figma specs in mind, using the `Inter` Google Font and specific, modern constraints.

## 📈 Development Progress (Phase Tracker)
- **Phase 1-6 (Backend)**: ✅ Completed. FastAPI models, auth routes, Neon PostgreSQL setup.
- **Phase 7-8 (Client Signup)**: ✅ Completed. Full UI and API integration for client registration.
- **Phase 9 (Professional Signup)**: ✅ Completed. 3-step registration, license upload flow, and pending verification screen.
- **Phase 10 (Client Home Screen)**: ✅ Completed. Fully functional home UI matching Figma, including 7-day streak, quick actions, upcoming sessions, and mood trends.
- **Phase 11 (Daily Check-in)**: ✅ Completed. Multi-step mood logging UI matching Figma, updated `MoodEntry` schemas, and API integration.
- **Phase 12 (Client Chatbot)**: ✅ Completed. Real-time chat interface connected to `POST /chat/sessions/{id}/messages` with empty states and typing indicators.
- **Phase 13 (Client Sessions Screens)**: ✅ Completed. `TherapySession` table on Neon PostgreSQL. `POST /sessions` (with conflict check), `GET /sessions/upcoming`, `GET /sessions/past` endpoints. Flutter screens: Upcoming, Past, and Book Session (calendar + hardcoded slots + reason dropdown + Online/In-person toggle). Wired into bottom navigation and Home Screen cards.
- **Phase 14 (Client Activity)**: ✅ Completed. Activity library UI and session start screens integrated.
- **Phase 15 (Client Profile)**: ✅ Completed. Profile screen with account info, settings, support links, and logout.
- **Phase 16 (Professional Dashboard)**: ✅ Completed. Mobile-first responsive Professional Dashboard with BottomNavigationBar + Drawer (mobile) and left Sidebar (desktop/tablet). Includes Triage & Alerts card (scoped strictly to the professional's own clients via `GET /professional/dashboard`), Active Patients & Pending Requests stat cards, and Today's Schedule. Verified professionals are routed here automatically after login.
- **Phase 17 (Professional Clients, Appointments & AI Insights)**: ✅ Completed. Added 3 core pages: Clients (data table / vertical list with filters), Appointments (calendar view + pending requests), and AI Insights (Flagged queue + AI report). Mobile-first responsive layouts wired into base navigation.
- **Phase 18 (Professional Reports & Settings)**: ✅ Completed. Reports screen with `fl_chart` grouped bar chart (PHQ-9 & GAD-7 Outcome Tracking), 3 metric cards, Crisis Protocol Metrics panel, RA 11036 Compliance card, Crisis Intervention Log modal, and Compliance PDF loading modal. Settings screen with profile edit, notification toggles, security, and logout.

## 🛠 Tech Stack

### Frontend (Mobile & Web)
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: `provider`
- **Networking**: `http`
- **Security**: `flutter_secure_storage`
- **Design System**: Custom theme mapping strictly to Figma prototypes (`google_fonts`)

### Backend (API)
- **Framework**: [FastAPI](https://fastapi.tiangolo.com/) (Python 3.12+)
- **Database ORM**: `SQLModel`
- **Database Engine**: [Neon PostgreSQL](https://neon.tech/)
- **Authentication**: `passlib`, `python-jose` (JWT), `bcrypt`
- **Environment Management**: `python-dotenv`

## 🚀 Getting Started

### 1. Running the Backend
Ensure you have Python installed, and navigate to the `backend` folder.
```bash
cd backend
python -m venv venv
# Activate the virtual environment
# Windows:
.\venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

pip install -r requirements.txt

# Start the development server
uvicorn app.main:app --reload
```
The API will be available at `http://127.0.0.1:8000`.

### 2. Running the Frontend
Ensure you have Flutter installed, and navigate to the `mobile` folder.
```bash
cd mobile
flutter pub get

# Run on the web (for desktop browser testing)
flutter run -d chrome

# Run on Android/iOS (requires active emulator/simulator)
flutter run
```

## 🔒 Environment Variables
Both frontend and backend require environment variable configuration.
- Backend: Uses a `.env` file containing the Neon DB `DATABASE_URL` and `SECRET_KEY`.
- Frontend: Base URL is configured inside `lib/config/api_config.dart`.

---
*© 2026 Kausap AI. Your Mental Clarity, Our Priority.*
