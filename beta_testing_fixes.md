# 🐛 Beta 10 — Bug Fix Implementation Plan

Bugs discovered from live testing on the physical Oppo A16 device.
All fixes are grouped into phases by risk level and dependency order.

---

## Phase 1 — Critical UX Blockers (Fix First)
These bugs break core user flows and will stop testers from even completing signup or navigation.

### Bug 1A: Default Dark Mode for New Users
**Problem:** The app defaults to `ThemeMode.system`, which on most Android phones means dark mode. First-time users see black input boxes with invisible text during Sign Up — a terrible first impression.

**Root Cause:** `ThemeProvider` starts with `ThemeMode.system` and only overrides it if a saved value is found in secure storage. New users have no saved value, so they get dark mode if their phone is set to dark.

**Fix:** Change the default `_themeMode` from `ThemeMode.system` to `ThemeMode.light` in `theme_provider.dart`. Only apply the saved preference for returning users.

**Files to change:**
- `mobile/lib/providers/theme_provider.dart` — Change line 10 default from `ThemeMode.system` → `ThemeMode.light`

---

### Bug 1B: Bottom Navigation Bar Missing in Activity Screen
**Problem:** When the user taps "Activity" in the bottom nav, the activity screen opens but the bottom nav bar disappears. The user is trapped and must use their phone's hardware back button.

**Root Cause:** The Activity screen is likely being pushed as a new route (`Navigator.push(...)`) instead of being displayed as a tab inside the existing `HomeScreen` widget that holds the bottom nav bar.

**Fix:** The Activity screen should be rendered as an indexed widget inside `HomeScreen` (like the other tabs), not pushed as a separate route.

**Files to change:**
- `mobile/lib/screens/home/home_screen.dart` — Ensure `_navIndex == 1` renders `ActivityScreen` inline.

---

### Bug 1C: Kausap (Chat) Bottom Nav Button Does Nothing
**Problem:** Tapping the "Kausap" icon in the bottom navigation bar doesn't navigate anywhere.

**Fix:** Wire the Kausap nav button to navigate to or render the `ChatbotScreen`.

**Files to change:**
- `mobile/lib/screens/home/home_screen.dart` — Wire `_navIndex == 2` to the `ChatbotScreen` widget.

---

### Bug 1D: Profile Page Has No Back Button
**Problem:** The Profile page has no back arrow in the header. Users are stuck on the profile page unless they use their phone's back button.

**Fix:** Add a leading back arrow (`IconButton` with `Navigator.pop`) to the Profile screen's AppBar.

**Files to change:**
- `mobile/lib/screens/profile/profile_screen.dart` — Add `leading: BackButton()` to the AppBar.

---

## Phase 2 — Functional Bugs (Core Features Broken)
These are features that exist in the UI but simply don't work correctly.

### Bug 2A: Profile Picture Does Not Save or Reflect Across the App
**Problem:** Uploading a profile picture or selecting an avatar shows a "success" toast, but the profile picture never actually changes — not on the profile screen and not on the home screen header.

**Root Cause (likely):** Two sub-problems:
1. The upload API call may be returning a new image URL, but the local `AuthProvider` state is never updated after the save, so the UI re-renders with the old data.
2. The home screen and other screens that show the avatar are reading `user['profile_picture_url']` from their initial `widget.user` parameter (which is stale), not from the live `AuthProvider`.

**Fix:**
- After a successful profile picture upload, call `AuthProvider.refreshUser()` to force all widgets that listen to the provider to rebuild with new data.
- Make all avatar icons across the app read from `context.watch<AuthProvider>().currentUser` instead of from a stale `widget.user` parameter.

**Files to change:**
- `mobile/lib/screens/profile/edit_profile_screen.dart` — After save, call `AuthProvider` to refresh user.
- `mobile/lib/screens/home/home_screen.dart` — Read avatar from `AuthProvider` instead of `widget.user`.
- `mobile/lib/providers/auth_provider.dart` — Add/expose a `refreshUser()` method if it doesn't exist.

---

### Bug 2B: Home Page Does Not Refresh When Tapped Again
**Problem:** Tapping the "Home" icon in the bottom nav bar while already on the home page does nothing. It should scroll back to the top and refresh all data.

**Fix:** Detect when `_navIndex` is tapped while already at `0`. Use a `ScrollController` and call `scrollController.animateTo(0)` when Home is tapped again. Also re-run data fetch methods to refresh content.

**Files to change:**
- `mobile/lib/screens/home/home_screen.dart` — Add `ScrollController` and handle "tap same tab" refresh logic.

---

## Phase 3 — UI Polish Bugs
These are visual inconsistencies that affect professionalism and user trust.

### Bug 3A: Profile Avatar Icon Inconsistent Across Pages
**Problem:** The avatar/initials shown in the home screen header (e.g., "V") is different from the one shown in other screens like Activity (e.g., "U"). The icon is not globally synced.

**Root Cause:** Different screens build the avatar icon using different data sources. Some use `widget.user['first_name']`, others use a locally-scoped user variable.

**Fix:** All avatar icons must read from the single source of truth: `context.read<AuthProvider>().currentUser`. Create a reusable `UserAvatar` widget that always reads from the provider, and replace all scattered avatar implementations with it.

**Files to change:**
- `mobile/lib/widgets/` — Create a new `user_avatar_widget.dart` reusable widget.
- `mobile/lib/screens/home/home_screen.dart` — Use `UserAvatar` widget.
- `mobile/lib/screens/activity/activity_screen.dart` — Use `UserAvatar` widget.

---

### Bug 3B: Google Sign-In Button Missing Google Logo
**Problem:** The "Sign in with Google" button on the Role Selection screen is missing the Google icon/logo.

**Fix:** Add the Google "G" logo as an image asset and display it as a leading icon on the button.

**Files to change:**
- `mobile/lib/screens/auth/role_selection_screen.dart` — Add Google "G" icon to the button.
- `mobile/assets/` — Add a `google_logo.png` asset if not already present.

---

## Phase 4 — Feature Enhancement (Daily Quests Automation)
This improves the integrity of the gamification system.

### Bug 4A: Daily Quests Are Manually Checkable (Allows Cheating)
**Problem:** Users can manually tap to complete daily quests without actually performing the action. This undermines the mental health data integrity of the capstone research.

**Fix:** Remove the manual tap-to-complete checkboxes. Instead, automatically mark quests as complete when the user performs the corresponding action:
- ✅ "Log your mood" — mark complete when `POST /mood` succeeds.
- ✅ "Write a journal entry" — mark complete when a journal entry is saved.
- ✅ "Complete a mindfulness exercise" — mark complete when an exercise is finished in the Activity screen.

**Files to change:**
- `mobile/lib/screens/home/home_screen.dart` — Remove manual quest tap logic.
- `mobile/lib/screens/mood/` — Trigger quest completion after successful mood log.
- `mobile/lib/screens/journal/` — Trigger quest completion after saving a journal.
- `mobile/lib/screens/activity/` — Trigger quest completion after completing an exercise.

---

## Execution Order & Commits

| Phase | Bug | Commit Message |
|-------|-----|---------------|
| **1A** | Dark mode default | `fix(theme): default to light mode for first-time users` |
| **1B** | Activity nav bar gone | `fix(nav): render Activity screen inline to preserve bottom nav bar` |
| **1C** | Kausap tab broken | `fix(nav): wire Kausap bottom nav to ChatbotScreen` |
| **1D** | No profile back button | `fix(profile): add back button to Profile screen AppBar` |
| **2A** | Profile pic not saving | `fix(profile): refresh AuthProvider after save so avatar updates everywhere` |
| **2B** | Home not refreshing | `fix(nav): scroll to top and refresh data when Home tab tapped again` |
| **3A** | Inconsistent avatars | `refactor(ui): create UserAvatar widget reading from AuthProvider` |
| **3B** | Missing Google logo | `fix(auth): add Google logo to Sign in with Google button` |
| **4A** | Manual quest cheating | `feat(quests): automate daily quest completion via action triggers` |
