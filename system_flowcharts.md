# Kausap AI — Comprehensive System Flowcharts

These flowcharts are structured specifically for your **Thesis / Capstone Defense**, showcasing the complete architectural flow, clinical safety guardrails (RA 11036 compliance), and AI empathy engine.

---

## 🏗️ 1. Complete End-to-End System Architecture Flowchart

```mermaid
graph TD
    classDef client fill:#E0F2FE,stroke:#0284C7,stroke-width:2px,color:#0369A1;
    classDef backend fill:#FEF3C7,stroke:#D97706,stroke-width:2px,color:#92400E;
    classDef ai fill:#DCFCE7,stroke:#16A34A,stroke-width:2px,color:#166534;
    classDef db fill:#F3E8FF,stroke:#9333EA,stroke-width:2px,color:#6B21A8;
    classDef safety fill:#FEE2E2,stroke:#DC2626,stroke-width:2px,color:#991B1B;

    subgraph MobileApp ["📱 Flutter Mobile Client (FSUU Students)"]
        UI_Home["Home Dashboard (Mood, Streaks, Quests)"]:::client
        UI_Chat["Kausap AI Chat (Personas, Audio, Voice)"]:::client
        UI_Insights["Trends & Screeners (PHQ-9, GAD-7)"]:::client
        UI_Articles["Wellness Articles & Coping Guides"]:::client
        OfflineQueue["Offline SQLite / SharedPreferences Queue"]:::client
    end

    subgraph BackendAPI ["⚙️ FastAPI Backend Core (Python 3.12)"]
        AuthMiddleware["JWT Authentication & Security"]:::backend
        MoodRouter["Mood & Streak Service"]:::backend
        ChatRouter["Chat Session & Telemetry Service"]:::backend
        AssessmentRouter["Clinical Screener Triage Service"]:::backend
        ArticlesRouter["Articles & Engagement API"]:::backend
    end

    subgraph AIDualEngine ["🧠 Dual AI Intelligence Engine"]
        Guardrails["Clinical Guardrails & Empathy Prompt Engine"]:::ai
        GeminiPrimary["Primary: Google Gemini 2.5 Flash"]:::ai
        GeminiBackup["Secondary: Gemini 2.5 Pro"]:::ai
        OpenAIFallback["Tertiary: OpenAI GPT-4o-mini"]:::ai
        OfflineFallback["Graceful Offline Calming Fallback"]:::ai
    end

    subgraph DatabaseLayer ["🗄️ Neon Serverless PostgreSQL"]
        DB_Users["Users & Student Profiles"]:::db
        DB_Moods["Mood Timeline & Streaks"]:::db
        DB_Chats["Encrypted Chat Messages & Token Logs"]:::db
        DB_Assessments["PHQ-9 / GAD-7 Screener Scores"]:::db
    end

    subgraph EmergencyHotlines ["🚨 Safety & Crisis Escalation"]
        NCMH["NCMH 1553 Crisis Hotline"]:::safety
        FSUU["FSUU Guidance Office Triage"]:::safety
    end

    UI_Home -->|1-Tap Mood Log| MoodRouter
    UI_Chat -->|User Message| ChatRouter
    UI_Insights -->|Submit PHQ-9/GAD-7| AssessmentRouter
    OfflineQueue -.->|Auto-Sync on Reconnect| MoodRouter

    MoodRouter --> DB_Moods
    AssessmentRouter --> DB_Assessments
    ChatRouter --> DB_Chats

    ChatRouter --> Guardrails
    Guardrails --> GeminiPrimary
    GeminiPrimary -.->|If Busy| GeminiBackup
    GeminiBackup -.->|If Timeout| OpenAIFallback
    OpenAIFallback -.->|If Disconnected| OfflineFallback

    Guardrails -->|Crisis Detected| EmergencyHotlines
```

---

## 🤖 2. AI Conversational Pipeline & Ethical Guardrails Flowchart

This flowchart demonstrates how Kausap AI processes every chat message to maintain ethical boundaries and zero-diagnosis safety.

```mermaid
flowchart TD
    classDef input fill:#EFF6FF,stroke:#3B82F6,stroke-width:2px,color:#1E40AF;
    classDef decision fill:#FEF3C7,stroke:#F59E0B,stroke-width:2px,color:#B45309;
    classDef safeAction fill:#DCFCE7,stroke:#10B981,stroke-width:2px,color:#065F46;
    classDef alertAction fill:#FEE2E2,stroke:#EF4444,stroke-width:2px,color:#991B1B;

    Start([💬 Student Types Message]):::input --> Layer1{Layer 1: Self-Harm or Crisis Detected?}:::decision

    Layer1 -- YES --> CrisisAction["🚨 Trigger NCMH 1553 & FSUU Guidance Crisis Sheet"]:::alertAction
    CrisisAction --> EndRisk([Display Immediate Emergency Support]):::alertAction

    Layer1 -- NO --> Layer2{Layer 2: Hourly Rate Limit Exceeded?}:::decision

    Layer2 -- YES --> RateLimit["⏳ Gentle Pacing Notice (Drink water, take a 10m break)"]:::safeAction
    RateLimit --> EndRate([Pacing Preserved]):::safeAction

    Layer2 -- NO --> Layer3{Layer 3: Asking for Medical Diagnosis or Medication?}:::decision

    Layer3 -- YES --> BoundaryAction["⚠️ Non-Clinical Boundary (Warmly redirect to Healthcare Professional)"]:::safeAction
    BoundaryAction --> EndBoundary([Safe Referral]):::safeAction

    Layer3 -- NO --> ContextAssembly["🧩 Assemble Context:<br>• Student Name & Program<br>• Selected Persona (Buddy/Ate Maya/Kuya Ben)<br>• Today's Mood Level<br>• Carl Rogers Empathy Principles"]:::safeAction

    ContextAssembly --> LLMCall["🧠 Call Gemini 2.5 Flash Engine"]:::safeAction
    LLMCall --> ResponseDelivery([✨ Deliver Empathetic, Culturally-Attuned Taglish Response]):::safeAction
```

---

## 🌿 3. Student Daily Wellness & Counselor Triage Journey

```mermaid
sequenceDiagram
    autonumber
    actor Student as 🧑‍🎓 Student (Van)
    participant App as 📱 Kausap Mobile App
    participant Server as ⚙️ FastAPI Backend
    participant DB as 🗄️ Neon Postgres
    participant Counselor as 🧑‍💼 Guidance Counselor

    Note over Student,App: Morning Wellness Routine
    Student->>App: Opens App ➔ Taps Daily Mood (🙂 Good)
    App->>Server: POST /mood (mood_level=4)
    Server->>DB: Insert MoodEntry with Timestamp
    Server-->>App: Return 200 OK + Updated Streak
    App-->>Student: Update Mascot Greeting & Daily Quest (1/3 Completed)

    Note over Student,App: Midday Emotional Shift
    Student->>App: Feeling stressed ➔ Taps (😟 Low)
    App->>Server: POST /mood (mood_level=2, factor='Thesis')
    Server->>DB: Append New MoodEntry
    App-->>Student: Wed Column shows 😟 + "2x" Badge (Average: 3.0)

    Note over Student,App: Bi-Weekly Clinical Screener (PHQ-9)
    Student->>App: Completes PHQ-9 Screener
    App->>Server: POST /screeners/phq9 (Score: 16 - Moderately Severe)
    Server->>DB: Store Assessment Result
    alt Score >= 15 (Distress Flag)
        Server->>Counselor: Flag in Counselor Dashboard for Follow-up
        Server-->>App: Provide Supportive Coping Modules & Counseling Booking
    else Score < 15
        Server-->>App: Provide Personalized Self-Care Recommendations
    end
```
