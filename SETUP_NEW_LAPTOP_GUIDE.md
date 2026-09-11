# 🚀 Kausap AI — New Laptop Setup & Dependency Installation Guide

This comprehensive guide lists all software, SDKs, dependencies, environment keys, and step-by-step commands needed to set up **Kausap AI** on a new laptop.

---

## 📋 Quick Summary Checklist

| Tool / Dependency | Version Recommendation | Purpose |
| :--- | :--- | :--- |
| **Git for Windows** | Latest (2.40+) | Version control & repository cloning |
| **Flutter SDK** | Stable (3.24.x – 3.47.x) | Mobile & Web application framework |
| **Dart SDK** | Bundled with Flutter (3.5+) | App language runtime |
| **Python** | 3.10, 3.11, 3.12, or 3.13 | Backend API runtime (`FastAPI`, `SQLModel`) |
| **Google Chrome** | Latest | Immediate web debugging (`flutter run -d chrome`) |
| **Android Studio** *(Optional for APK)* | Latest Ladybug / Iguana | Android SDK, Command-line Tools, Emulator |
| **Antigravity IDE / VS Code** | Latest | AI pair programming & code editing |

---

## 🛠️ Step 1: Install Required Software on New Laptop

### 1. **Git for Windows**
- **Download:** [https://git-scm.com/download/win](https://git-scm.com/download/win)
- **Install:** Run installer with default options.
- **Verify in PowerShell:**
  ```powershell
  git --version
  ```

---

### 2. **Flutter SDK**
- **Download:** [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows)
- **Setup:**
  1. Extract the zip file to `C:\src\flutter` (do NOT install in `C:\Program Files`).
  2. Add `C:\src\flutter\bin` to your Windows **Environment Variables (`PATH`)**.
  3. Open a new PowerShell window and run:
     ```powershell
     flutter doctor
     ```

---

### 3. **Python (3.10 – 3.13)**
- **Download:** [https://www.python.org/downloads/](https://www.python.org/downloads/)
- ⚠️ **CRITICAL:** Check the box **"Add python.exe to PATH"** on the first installation screen!
- **Verify in PowerShell:**
  ```powershell
  python --version
  ```

---

### 4. **Google Chrome**
- **Download:** [https://www.google.com/chrome/](https://www.google.com/chrome/)
- Used for instant, zero-setup Flutter web testing (`flutter run -d chrome`).

---

### 5. **Android Studio** *(Only needed if building Android APK / running Android Emulator)*
- **Download:** [https://developer.android.com/studio](https://developer.android.com/studio)
- **Setup:** Open Android Studio → **SDK Manager** → **SDK Tools** → check:
  - ✅ **Android SDK Build-Tools**
  - ✅ **Android SDK Command-line Tools (latest)**
  - ✅ **Android SDK Platform-Tools**
- Run `flutter doctor --android-licenses` in terminal and accept prompts.

---

## 📥 Step 2: Clone the Project from GitHub

1. Open PowerShell on the new laptop.
2. Navigate to your desired workspace folder (e.g. `C:\`):
   ```powershell
   cd C:\
   git clone https://github.com/devbalbuena/Kausap-AI.git
   cd Kausap-AI
   ```

---

## 🔐 Step 3: Copy Your Secret `backend/.env` File

API keys and database connection strings are never committed to GitHub for security.

1. On your **old laptop**, open: `C:\Kausap-AI\backend\.env`
2. Copy the `.env` file (via USB flash drive, Google Drive, or secure message).
3. On your **new laptop**, paste it into:
   ```text
   C:\Kausap-AI\backend\.env
   ```

### 📄 `.env` File Reference Format:
```dotenv
# Database (Neon Serverless Postgres)
DATABASE_URL=postgresql://user:password@ep-xxxx.neon.tech/neondb?sslmode=require

# Security / JWT
SECRET_KEY=your-jwt-secret-key

# AI Provider
OPENAI_API_KEY=sk-proj-your-openai-api-key

# Fallback AI Providers (Optional)
GEMINI_API_KEY=AIzaSy...
MISTRAL_API_KEY=...

# Voice Synthesis (Optional)
ELEVENLABS_API_KEY=sk_...
ELEVENLABS_VOICE_ID=21m00Tcm4TlvDq8ikWAM

# Brevo Transactional Email (For 6-Digit OTP, Counselor Provisioning & Call-Slips)
BREVO_API_KEY=xkeysib-your-brevo-api-key
BREVO_SENDER_EMAIL=your-verified-brevo-email@gmail.com
BREVO_SENDER_NAME=Kausap AI - Guidance & Counseling Office
```

---

## 📦 Step 4: Install Dependencies

### 🐍 1. Setup Backend (FastAPI + SQLModel)
Open PowerShell in the project root:
```powershell
cd C:\Kausap-AI\backend

# 1. Create Python virtual environment
python -m venv venv

# 2. Activate virtual environment
.\venv\Scripts\activate

# 3. Install all pip dependencies
pip install -r requirements.txt

# 4. Verify tests pass (0 errors)
python test_all_phases.py
```

### 📱 2. Setup Mobile / Frontend (Flutter)
Open PowerShell in the project root:
```powershell
cd C:\Kausap-AI\mobile

# 1. Download Flutter packages
flutter pub get

# 2. Verify code analysis is 100% clean
flutter analyze
```

---

## 🚀 Step 5: Running the System

### Terminal 1 — Start the Backend Server:
```powershell
cd C:\Kausap-AI\backend
.\venv\Scripts\activate
uvicorn app.main:app --reload --port 8000
```
- API Swagger Docs: `http://localhost:8000/docs`

### Terminal 2 — Start the Flutter App:
```powershell
cd C:\Kausap-AI\mobile

# Run in Chrome browser (Fastest for testing):
flutter run -d chrome

# Or run on connected Android phone / emulator:
flutter run
```

---

## 🔑 Default Test Accounts & Roles

| Role | Email | Password | Access / Destination |
| :--- | :--- | :--- | :--- |
| 🛡️ **Super Admin** | `admin@kausap.ai` | `Admin@123456` | **Admin Control Center** (Student Directory, Provision Counselors, Audit Logs, Telemetry). |
| 🩺 **Counselor** | *(Created via Admin)* | *(Sent via Brevo Email)* | **Counselor Clinical Portal** (Active Triage, In Action Call-Slips, Resolved Logs). |
| 👤 **Student / Client** | `balbuenadexter2@gmail.com` | `Password@123` | **Student App** (Home, SOS Hotline, Kausap Chat, Mood Check-in, Guidance Mailbox). |

---

## 💡 Quick Tips for Antigravity IDE on New Laptop
1. Download & open **Antigravity IDE**.
2. Go to **File → Open Folder** and select `C:\Kausap-AI`.
3. In your first chat, you can say:
   > *"Hi! I just cloned the repository to my new laptop. Please check where we left off."*
   Antigravity will automatically inspect the codebase and continue seamlessly!
