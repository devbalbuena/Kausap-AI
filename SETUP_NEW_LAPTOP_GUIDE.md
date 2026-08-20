# 🚀 Kausap AI — New Laptop Setup & Installation Guide (Method 1)

This guide walks you through setting up and running **Kausap AI** on your new laptop in just a few simple steps.

---

## 📋 Table of Contents
1. [Step 1: Install Required Software](#-step-1-install-required-software)
2. [Step 2: Clone the Project (Method 1)](#-step-2-clone-the-project-method-1)
3. [Step 3: Copy the Secret `.env` File](#-step-3-copy-the-secret-env-file)
4. [Step 4: Install Dependencies & Verify](#-step-4-install-dependencies--verify)
5. [Step 5: Starting a New Chat in Antigravity IDE](#-step-5-starting-a-new-chat-in-antigravity-ide)
6. [🔑 Test Accounts & Credentials](#-test-accounts--credentials)

---

## 🛠️ Step 1: Install Required Software

Install the following tools on the new laptop:

### 1. **Git for Windows**
* **Download:** [https://git-scm.com/download/win](https://git-scm.com/download/win)
* **Installation:** Run installer and keep the default settings.

### 2. **Flutter SDK**
* **Download:** [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows)
* **Setup:**
  1. Extract the zip file to `C:\src\flutter` (do NOT extract inside `Program Files`).
  2. Add `C:\src\flutter\bin` to your Windows **Environment Variables (PATH)**.
  3. Open a new PowerShell / Command Prompt and verify:
     ```bash
     flutter doctor
     ```

### 3. **Android Studio (or Physical Android Phone)**
* **Download:** [https://developer.android.com/studio](https://developer.android.com/studio)
* **Setup:** Open Android Studio → **SDK Manager** → **SDK Tools** → check **"Android SDK Command-line Tools"** and click **Apply**.
* *(Alternative)*: You can test directly on your physical Android phone by enabling **Developer Options → USB Debugging**.

### 4. **Python 3.10 or 3.11** *(Optional — for local backend)*
* **Download:** [https://www.python.org/downloads/](https://www.python.org/downloads/)
* ⚠️ **Important:** During installation, make sure to check the box **"Add Python to PATH"**.

---

## 📥 Step 2: Clone the Project (Method 1)

1. Open PowerShell or Command Prompt on the new laptop.
2. Choose where you want to store the project (e.g., `C:\` or `C:\Users\<Name>\Documents`):
   ```bash
   cd C:\
   git clone https://github.com/devbalbuena/Kausap-AI.git
   ```
3. Navigate into the cloned folder:
   ```bash
   cd Kausap-AI
   ```

---

## 🔐 Step 3: Copy the Secret `.env` File

For security, API keys and database credentials are not stored on GitHub. You need to copy your `backend/.env` file from the old laptop:

1. On your **old laptop**, open the folder: `c:\kausap-ai\backend\`
2. Copy the file named `.env` to a USB flash drive (or send the text to yourself on Messenger/Discord).
3. On your **new laptop**, paste it into:
   ```text
   Kausap-AI\backend\.env
   ```

---

## 📦 Step 4: Install Dependencies & Verify

### 📱 1. Mobile App Setup:
1. In PowerShell, navigate to the `mobile` folder:
   ```bash
   cd mobile
   flutter pub get
   ```
2. Run analyzer to confirm everything is 100% clean:
   ```bash
   dart analyze lib
   ```
   *(It should say `No issues found!`)*

3. Run the app on an emulator or connected phone:
   ```bash
   flutter run
   ```

> 💡 **Note:** The mobile app is already connected to your live cloud backend on Render (`https://kausap-ai.onrender.com`) and cloud Neon Postgres DB, so you don't even need to run a local backend to test!

---

### 🐍 2. Local Backend Setup *(Optional)*:
If you want to run the FastAPI backend locally:
```bash
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

---

## 💬 Step 5: Starting a New Chat in Antigravity IDE

1. Open **Antigravity IDE** on your new laptop.
2. Click **File → Open Folder** and select `C:\Kausap-AI` (or wherever you cloned it).
3. Start a new chat with Antigravity! You can simply say:

> *"Hi! I just cloned this project to my new laptop. Please review `walkthrough.md` and let me know where we stand."*

The AI assistant will automatically read the full project history, previous decisions, and architecture from `walkthrough.md` and `implementation_plan.md` and continue assisting you seamlessly!

---

## 🔑 Test Accounts & Credentials

| Role | Email | Password | What Happens on Login |
|---|---|---|---|
| 🛡️ **Administrator** | `admin@kausap.ai` | `Admin@123456` | Automatically opens the **Admin Control Center** (Student Directory, Crisis Moderation, RA 11036 Compliance). |
| 👤 **Student / User** | `balbuenadexter2@gmail.com` | `Password@123` | Automatically opens the **Student Wellness App** (Home, Activity Hub, Kausap AI Chat, 📊 Insights & Screeners Hub). |

---

## 📲 Direct APK Download (Beta 15)
If you just want to install the latest build on your Android phone right now:
* 🔗 **Latest Release Page:** [https://github.com/devbalbuena/Kausap-AI/releases/tag/beta-v15](https://github.com/devbalbuena/Kausap-AI/releases/tag/beta-v15)
* 📥 **Direct APK Download:** [Download arm64-v8a APK](https://github.com/devbalbuena/Kausap-AI/releases/download/beta-v15/KausapAI-beta-build15-2026-08-19-arm64-v8a.apk)
