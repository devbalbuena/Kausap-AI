# Kausap AI 💚

> **Your Mental Wellness Companion.**  
> Kausap AI is a full-stack mental health platform connecting clients with licensed professionals through AI-powered chatbot support, mood tracking, session booking, and secure messaging — built with Flutter and FastAPI.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.11x-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Neon PostgreSQL](https://img.shields.io/badge/Neon-PostgreSQL-00E699?logo=postgresql)](https://neon.tech)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📱 Project Structure

This is a **monorepo** containing both the Flutter frontend and FastAPI backend.

```
kausap-ai/
├── mobile/          # Flutter app (iOS · Android · Web)
│   ├── lib/
│   │   ├── screens/       # All feature screens
│   │   ├── widgets/       # Reusable UI components
│   │   ├── providers/     # State management (Provider)
│   │   ├── services/      # API service layer
│   │   ├── utils/         # Helpers (routes, haptics)
│   │   ├── theme/         # Design system & app theme
│   │   └── config/        # API config & constants
│   └── pubspec.yaml
└── backend/         # FastAPI REST API (Python 3.12+)
    ├── app/
    │   ├── routers/       # API route handlers
    │   ├── models/        # SQLModel database models
    │   └── main.py
    └── requirements.txt
```

---

## ✨ Features

### 👤 Authentication & Onboarding
- **Role-based access** — Separate, tailored experiences for **Clients** (patients) and **Professionals** (counselors/psychologists)
- **JWT Authentication** — Secure token-based login with `flutter_secure_storage`
- **Multi-step signup** — Guided 3-step registration flows for both client and professional roles
- **Professional verification** — License upload & admin approval flow with a "Pending" holding screen
- **Animated splash & onboarding** — Beautiful branded launch screens

### 🤖 AI Chatbot (Kausap AI)
- **Real-time conversation** — Chat interface connected to the AI session API
- **Typing indicators** — Animated response indicators for a natural feel
- **Empty states** — Friendly prompts when no conversation exists
- **Risk-flagging** — Backend capability to detect at-risk messages

### 🏠 Client Home Screen
- **7-day mood streak** — Gamified daily check-in tracking
- **Quick action cards** — One-tap access to Check-in, Chatbot, Find a Professional, and Direct Message
- **Upcoming sessions widget** — Live data from the database with skeleton loading
- **Daily motivational quotes** — Dynamic quote cards
- **Suggested activities** — Curated wellness activity recommendations
- **Mood trend chart** — Weekly mood visualization using `fl_chart`
- **Pull-to-Refresh** — Branded Kausap AI refresh indicator

### 📅 Session Booking (Availability & Booking UI)
- **Horizontal scrolling date picker** — Calendar-style date selection
- **Time slot grid** — Visual, selectable session time slots (e.g., 9:00 AM, 10:30 AM)
- **Booking conflict detection** — Backend prevents double-booking
- **Upcoming sessions tracker** — Home screen widget showing next scheduled session
- **Booking Confirmed** screen — Animated success screen after booking
- **Cancel session** — One-tap cancel with a confirmation dialog

### 🔍 Discover Professionals
- **Professional cards** — Browse verified therapists and counselors
- **Search & specialty filters** — Filter by specialization (Anxiety, Depression, ADHD, Trauma, etc.)
- **Professional profile screen** — Full bio, stats, location, and specialization details
- **Hero animations** — Avatars fly smoothly from the list into the detail screen
- **Skeleton loading** — Shimmer effect card placeholders during data fetch
- **Empty states** — Clear UI when no results match the filter

### 💬 Messaging
- **Direct messaging** — Real-time 1-on-1 chat with professionals
- **Chat history** — Full message thread with timestamps
- **Empty state** — Friendly prompt when no messages exist yet

### 🧘 Daily Check-in & Mood Tracking
- **3-step mood logging** — Guided emoji + slider-based mood entry UI
- **Mood history** — Past mood entries stored and tracked over time
- **Activity library** — Wellness exercises (breathing, journaling, etc.)
- **Activity session screen** — In-session guided activity experience

### 🔔 Notifications
- **Notification feed** — All app alerts in a scrollable list
- **Unread badge** — Real-time badge counter on the notification icon
- **Mark-all-as-read** — One-tap clear action
- **Empty state** — "You're all caught up!" screen

### 👨‍⚕️ Professional Dashboard
- **Role-protected routing** — Verified professionals are automatically directed here
- **Responsive layout** — BottomNavigationBar on mobile, Sidebar on tablet/desktop
- **Triage & Alerts card** — Scoped strictly to the professional's own clients
- **Client management** — Data table with search and filter
- **Appointment calendar** — View and manage scheduled sessions
- **AI Insights panel** — Flagged queue and AI-generated client reports
- **Outcome tracking reports** — `fl_chart` grouped bar chart for PHQ-9 & GAD-7
- **Crisis Intervention Log** — Modal-based log for compliance
- **RA 11036 Compliance** card — Philippine mental health law compliance tracking

### ⚙️ Profile & Settings
- **Edit profile** — Update personal info and display picture
- **Dark Mode** — Full dark color palette with `ThemeMode` toggle via Provider
- **Notification settings** — Granular notification preference toggles
- **Privacy screen** — Data privacy controls and policy links

### 🔐 Security Features
- **Privacy Screen** — Blurs app content in the iOS/Android recent apps switcher
- **Session Timeout** — Auto-lock after 15 minutes of background inactivity
- **Change Password** — With real-time password strength meter (progress bar)
- **Active Devices / Login History** — Shows all active sessions across devices dynamically
- **Log out all other devices** — Secure confirmation dialog
- **Two-Factor Authentication (2FA)** — 4-step setup flow with mock QR code and 6-digit PIN entry
- **Data Export UI** — Request a download of chat history and mood data (privacy compliance)

### 🎨 UI/UX & Polish
- **Custom page transitions** — Smooth 320ms `slide` and `fade` `PageRoute` animations (no abrupt screen cuts)
- **Shimmer skeleton loaders** — Replace spinners with content-shaped loading placeholders on Home and Discover
- **Generic Empty State widget** — Reusable component with icon, title, description, and CTA button across all screens
- **Haptic feedback** — Subtle vibrations on button taps, toggle switches, success, and error events
- **Rate App dialog** — 5-star rating modal that appears after successful key actions
- **Help & FAQ screen** — Expandable accordion tiles with support contact button
- **Branded pull-to-refresh** — Custom Kausap AI indicator on Home and Discover screens
- **Admin moderation panel** — User management and content moderation tools

---

## 🛠 Tech Stack

### Frontend (Mobile & Web)
| Technology | Purpose |
|---|---|
| [Flutter](https://flutter.dev/) (Dart) | Cross-platform UI framework |
| `provider` | State management |
| `http` | REST API networking |
| `flutter_secure_storage` | Encrypted token storage |
| `google_fonts` | Poppins / Urbanist typography |
| `fl_chart` | Mood trend & outcome charts |
| `shimmer` | Skeleton loading effects |
| `image_picker` | Profile photo upload |
| `vibration` | Haptic feedback patterns |
| `intl` | Date/time formatting |

### Backend (API)
| Technology | Purpose |
|---|---|
| [FastAPI](https://fastapi.tiangolo.com/) (Python 3.12+) | REST API framework |
| `SQLModel` | Database ORM |
| [Neon PostgreSQL](https://neon.tech/) | Serverless PostgreSQL database |
| `passlib` + `bcrypt` | Password hashing |
| `python-jose` (JWT) | Token authentication |
| `python-dotenv` | Environment variable management |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Python 3.12+
- A [Neon](https://neon.tech) PostgreSQL project (free tier is fine)

### 1. Clone the Repository
```bash
git clone https://github.com/devbalbuena/Kausap-AI.git
cd Kausap-AI
```

### 2. Set Up the Backend
```bash
cd backend
python -m venv venv

# Windows
.\\venv\\Scripts\\activate
# Mac/Linux
source venv/bin/activate

pip install -r requirements.txt
```

Create a `.env` file inside `/backend`:
```env
DATABASE_URL=postgresql+psycopg2://your_neon_connection_string
SECRET_KEY=your_super_secret_key
```

Start the API server:
```bash
uvicorn app.main:app --reload
```
The API will be available at `http://127.0.0.1:8000`. Swagger docs at `http://127.0.0.1:8000/docs`.

### 3. Set Up the Frontend
```bash
cd mobile
flutter pub get
```

Update the base URL in `lib/config/api_config.dart` to point to your backend:
```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

Run the app:
```bash
# Web (browser)
flutter run -d chrome

# Android/iOS (requires emulator/device)
flutter run
```

---

## 📈 Development History (Phase Tracker)

| Phase | Description | Status |
|---|---|---|
| 1–6 | Backend: FastAPI models, auth routes, Neon PostgreSQL setup | ✅ Done |
| 7–8 | Client Signup: 3-step registration UI & API integration | ✅ Done |
| 9 | Professional Signup: License upload, pending verification screen | ✅ Done |
| 10 | Client Home Screen: Streak, quick actions, sessions, mood trends | ✅ Done |
| 11 | Daily Check-in: 3-step mood logging UI & API integration | ✅ Done |
| 12 | Client Chatbot: Real-time AI chat with typing indicators | ✅ Done |
| 13 | Session Booking: Calendar, time slots, conflict check, cancel | ✅ Done |
| 14 | Client Activity: Activity library & session start screens | ✅ Done |
| 15 | Client Profile: Account info, settings, support, logout | ✅ Done |
| 16 | Professional Dashboard: Responsive layout, triage, stats | ✅ Done |
| 17 | Professional Clients, Appointments & AI Insights | ✅ Done |
| 18 | Professional Reports & Settings: Charts, compliance, crisis log | ✅ Done |
| 19 | Availability & Booking UI: Horizontal calendar, time slots, animated booking confirmed | ✅ Done |
| 20 | Dark Mode: Full dark palette, ThemeMode toggle, Provider state | ✅ Done |
| 21 | Device Privacy & App Lock: Privacy screen, session timeout, data export UI | ✅ Done |
| 22 | Account Security: Change password (strength meter), active devices, 2FA setup | ✅ Done |
| 23 | Enhanced Onboarding & Empty States: Empty states, shimmer loaders, FAQ, Rate App dialog | ✅ Done |
| 24 | Micro-Interactions & Delight: Custom page transitions, Hero animations, haptics, branded PTR | ✅ Done |

---

## 🔒 Environment Variables

| Variable | Location | Purpose |
|---|---|---|
| `DATABASE_URL` | `backend/.env` | Neon PostgreSQL connection string |
| `SECRET_KEY` | `backend/.env` | JWT signing secret |
| `baseUrl` | `mobile/lib/config/api_config.dart` | Backend API base URL |

---

## 📁 Key Files & Architecture

```
mobile/lib/
├── utils/
│   ├── app_routes.dart          # Custom slide/fade PageRoute transitions
│   └── haptic_service.dart      # Centralized haptic feedback patterns
├── widgets/
│   ├── empty_state_widget.dart       # Reusable empty state component
│   ├── skeleton_loading_widget.dart  # Shimmer loading placeholders
│   ├── branded_refresh_indicator.dart# Custom pull-to-refresh
│   ├── rate_app_dialog.dart          # Star rating feedback dialog
│   └── privacy_wrapper.dart          # App content blurring for privacy screen
├── providers/
│   ├── auth_provider.dart        # JWT auth state
│   └── theme_provider.dart       # Dark/light mode state
└── theme/
    └── app_theme.dart            # Full design system (light + dark palettes)
```

---

## 🤝 Contributing

This project is a portfolio piece. Feel free to fork and use it as a reference. PRs are welcome for bug fixes.

---

*© 2026 Kausap AI — Your Mental Clarity, Our Priority.*
