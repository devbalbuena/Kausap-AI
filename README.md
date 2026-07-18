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
- **Unified Design System**: Built with Figma specs in mind, using the `Inter` Google Font and specific, modern constraints.

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
