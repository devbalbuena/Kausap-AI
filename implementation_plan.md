# Kausap AI — Remaining Build Phases

> Based on full Figma audit. Phases are sized so each one is completable in one session.
> ✅ = Already done | 🔲 = Remaining

---

## ✅ Already Complete

| Area | What Was Built |
|---|---|
| Backend | Auth, Mood, Chat, Referrals, Admin panel endpoints |
| Backend | User model (Client + Professional + Admin roles) |
| Backend | ProfessionalProfile model with `is_verified` |
| Flutter | API client, token storage, auth service, auth provider |
| Flutter | Role Selection screen |
| Flutter | Unified Login screen (with error states) |
| Flutter | Placeholder Home screen |
| Flutter | Design system (Inter font, colors, theme) |

---

## Phase 8 — Client Signup Flow (Multi-Step)

**Figma frames:** `Client Signup - Step 1`, `Step 2`, `Step 3`

- Step 1: First name, last name, email, phone, birthday, gender, password
- Step 2: Occupation (dropdown), address (optional), bio (optional)
- Step 3: Summary/review screen + submit → POST /auth/register (role: client)
- Progress bar between steps (Figma shows it)
- Navigation: Back button between steps, role_selection_screen on cancel

---

## Phase 9 — Professional Signup Flow (Multi-Step)

**Figma frames:** `Professional Signup - Step 1`, `Step 2`, `Step 3`, `Professional Pending Login`

- Step 1: Same basic info as Client Step 1
- Step 2: Profession, PRC license number, upload (just field for now), specialization, years of experience, bio, accepting clients toggle, location
- Step 3: Summary/review + submit → POST /auth/register (role: professional)
- After submit: show the `Professional Pending Login` screen — "Your account is pending verification"

---

## Phase 10 — Client Home Screen

**Figma frames:** `Client/Home`

- Top header: logo + bell notification + streak counter
- "Feeling today?" daily check-in prompt (→ links to Check-in flow)
- "Chat with Kausap AI" quick-access card
- "Upcoming Session" section
- "Suggested Activity" card
- "Mood Trends" mini-chart card
- Bottom navbar: Home | Activities | Sessions | Profile

---

## Phase 11 — Client Daily Check-in

**Figma frames:** `Client/Daily Check-in/1`, `/2`, `/3`, `/Complete`

- Step 1: Mood scale selection (Great / Good / Okay / Low / Very Low)
- Step 2: Visual slider for intensity
- Step 3: Notes input
- Complete: Confirmation screen with illustration
- Connects to POST /mood backend endpoint

---

## Phase 12 — Client Chatbot Screen

**Figma frames:** `Client/Chatbot Empty`, `Client/Chatbot Convo`

- Empty state: Disclaimer banner + quick reply chips
- Conversation state: Scrollable chat history (AI + User messages)
- Typing indicator animation
- Message input form with send button
- Connects to POST /chat backend endpoint

---

## Phase 13 — Client Sessions Screens

**Figma frames:** `Client/Session/Book`, `Client/Session/Upcoming`, `Client/Session/Past`

- Book: Calendar picker + time slots + reason dropdown + mode toggle (online/in-person)
- Upcoming: Card showing next scheduled session
- Past: History list of completed sessions

---

## Phase 14 — Client Activity Screen

**Figma frames:** `Client/Activity`, `Client/Activity/Start`

- Browse activities with category tabs + search
- Featured streak card
- Start screen: hero image, how-it-works steps, tags

---

## Phase 15 — Client Profile Screen

**Figma frames:** `Client/Profile`

- "My Mental Health" section
- Settings list: account, privacy, help, etc.

---

## Phase 16 — Professional Dashboard (Desktop)

**Figma frames:** `Professional/Dashboard`

- Sidebar navigation (Dashboard, Clients, AI Insights, Appointments, Activities, Reports, Settings)
- Bento grid: Urgent Triage Alerts + Stat Cards + Today's Schedule
- "New Appointment" modal card

---

## Phase 17 — Professional Clients, Appointments, AI Insights

**Figma frames:** `Professional/Clients`, `Professional/Appointments/Day|Week|Month|Year`, `Professional/AI Insights`

- Clients: Paginated data table with search
- Appointments: Day/Week/Month/Year calendar views + pending request cards
- AI Insights: Metric cards + patient queue + AI summary panel

---

## Phase 18 — Professional Reports & Settings

**Figma frames:** `Professional/Reports`, `Professional/Settings`

- Reports: Metric cards + bar chart + crisis log modal + date picker
- Compliance panel
- Settings page

---

## Recommended Next Order

| Priority | Phase | Why |
|---|---|---|
| 🔥 Next | **Phase 8** — Client Signup | Completes the core auth loop. Can't use the app without registering. |
| 2nd | **Phase 9** — Professional Signup | Completes the professional onboarding |
| 3rd | **Phase 10** — Client Home | The first real screen after login |
| 4th | **Phase 11** — Daily Check-in | Core mental health feature, short to build |
| 5th | **Phase 12** — Chatbot | The main AI feature — the heart of the thesis |
| Later | Phases 13–15 | Sessions, Activities, Profile |
| Last | Phases 16–18 | Professional dashboard (desktop/admin-style, lower thesis priority) |
