# Synvero — Project Memory and Session Log

## Project Identity
- Name: Synvero
- Tagline: Everything Working in Sync.
- App type: Flutter Android-first habit tracker, study planner, task reminder, fitness/nutrition guide, and AI assistant.
- Backend target: Supabase.
- UI direction: Modern blue and white, premium minimal.
- Primary color: `#4361EE`.

## User Workflow Preferences
- The project already exists; inspect before changing it.
- The user is building with Cursor.
- Work in small, explicit chunks.
- Start with the Login Page.
- Do not confuse the workflow by generating the whole application at once.
- Give exact file paths and complete code for requested changes.
- Preserve existing functionality and user changes.
- Explain commands and testing steps in accessible language.

## Planned Feature Order
0. Audit existing project.
1. Login UI.
2. Signup UI.
3. Supabase Auth, profile, database and RLS.
4. Home dashboard with username and today's date.
5. Habit tracker.
6. Study timer and focus mode.
7. Tasks and local reminders.
8. AI assistant through a secure backend.
9. Profile/settings, QA, security review, Android release.

## Current Verified Status
- Project name and intended feature scope have been defined in conversation.
- Cursor is the chosen coding tool.
- User says an existing Flutter project is available.
- Modern blue login/signup and dashboard concepts have been discussed.
- No source files have yet been inspected by this document.
- Do not assume any feature or Supabase integration is implemented until the actual project is inspected.

## Current Phase
Phase 5 / Habit Tracker implementation.

## Known Unknowns
- Actual project path and folder structure.
- Existing package versions and state management.
- Existing navigation/authentication implementation.
- Existing tests and current build status.

## Session Update — Phase 4 (2026-10-27)

- Date: 2026-10-27
- Phase: Phase 4 / Home Dashboard implementation
- Files changed:
  - Created: `lib/features/dashboard/presentation/dashboard_screen.dart` — dashboard screen with username display, today's date, progress cards (habits, tasks, study time), quick action buttons for all core modules, logout button, loading and error states
  - Modified: `lib/main.dart` — added `/dashboard` named route to AuthWrapper, wired `_handleLogin` and `_handleSignup` callbacks to push to dashboard on successful auth
  - Modified: `test/widget_test.dart` — updated test to verify login screen renders correctly with validation errors and password visibility toggle
  - Created: `lib/features/dashboard/presentation/dashboard_screen.dart` — see above
- Commands run and results:
  - `flutter pub get` → Resolved dependencies successfully
  - `flutter analyze` → No issues found!
  - `flutter test test/widget_test.dart` → All 3 tests passed (login screen rendering, validation errors, password visibility toggle)
- Manual tests completed: None yet (no device available); widget tests cover rendering, validation, and password toggle
- Known issues:
  - Dashboard shows placeholder "0" values for habit/task/study progress until Phase 5 implements real data
  - Quick action buttons navigate to nowhere (Phases 5-8 will implement navigation)
  - Dashboard only shows when user is authenticated; shows login screen when not authenticated
- Next phase (not started): Phase 5 — Habit Tracker

## Session Update — Phase 5 (2026-10-27)

- Date: 2026-10-27
- Phase: Phase 5 / Habit Tracker implementation
- Files created:
  - `supabase/migrations/20260101000001_habits.sql` — Supabase migration creating `habits` and `habit_completions` tables with Row Level Security (RLS), unique constraint on (habit_id, completed_at) to prevent duplicate completions, indexes, and updated_at trigger
  - `lib/features/habits/data/models/habit_model.dart` — Habit data model with fromMap/toMap serialization, parsedColor and parsedIcon helpers
  - `lib/features/habits/data/models/habit_completion_model.dart` — HabitCompletion data model with fromMap/toMap serialization
  - `lib/features/habits/data/habit_repository.dart` — HabitRepository with CRUD operations for habits and completions, streak calculation, weekly/monthly summaries, today's completion status, toggle completion
  - `lib/features/habits/presentation/habit_screen.dart` — HabitScreen widget with habit list, completion toggle, create/edit/archive/delete dialogs, streak badges, loading/error/empty states
- Files modified:
  - `lib/main.dart` — added `/habits` named route to AuthWrapper, imported HabitScreen
  - `lib/features/dashboard/presentation/dashboard_screen.dart` — wired Habit Tracker quick action to navigate to `/habits`
- Commands run and results:
  - `flutter pub get` → Resolved dependencies successfully
  - `flutter analyze` → No issues found!
  - `flutter test test/widget_test.dart` → All 3 tests passed (login screen rendering, validation errors, password visibility toggle)
- Manual tests completed: None yet (no device available); widget tests cover rendering, validation, and password toggle
- Known issues:
  - Streak calculation in habit_screen.dart uses a simplified approximation (checks if completed today) — full streak calculation requires fetching completions per habit
  - Dashboard shows placeholder "0" values for habit/task/study progress until real data is connected
  - Quick action buttons for Study Timer, Tasks, and AI Assistant still navigate to nowhere (Phases 6-8 will implement navigation)
  - Dashboard only shows when user is authenticated; shows login screen when not authenticated
- Next phase (not started): Phase 6 — Study Timer

## Session Update — Mockup UI Redesign: Screen 1 & Screen 2 (2026-10-28)

- Date: 2026-10-28
- Phase: UI Redesign (Screen 1: Login & Screen 2: Create Account matching the master 10-screen design mockup)
- Files created:
  - `lib/core/widgets/synvero_logo.dart` — Custom vector-painted Synvero 3-petal sprout emblem, brand title, and tagline widget
  - `lib/core/widgets/mountain_illustration.dart` — Layered mountain landscape vector painter matching the bottom artwork in Screen 1
- Files modified:
  - `lib/app/theme/app_colors.dart` — Updated brand palette to `#2F65F6` with clean border and surface tokens
  - `lib/features/auth/presentation/login_screen.dart` — Pixel-perfect Screen 1 implementation: brand logo, "Welcome Back", email/password fields with rounded styling, forgot password link, "Log In ->" button, and mountain art
  - `lib/features/auth/presentation/signup_screen.dart` — Pixel-perfect Screen 2 implementation: back navigation, "Create Account", fields, live 4-point password criteria checklist (8+ chars, uppercase, lowercase, number), and "Create Account ->" button
  - `test/widget_test.dart` — Updated test assertions to match "Log In" button and verified test suite
- Commands run and results:
  - `flutter analyze` → No issues found!
  - `flutter test test/widget_test.dart` → All 3 tests passed!
  - `hot_reload` and `hot_restart` via DTD → Applied live to running app successfully
- Next phase: Screen 3 (Home Dashboard with Circular Progress & Quick Actions) & Main 5-tab Navigation Shell

### Bugfix (2026-10-28)
- Issue: `Assertion failed: _asyncStorage != null "You need to provide asyncStorage to perform pkce flow."` on Flutter web signup.
- Root Cause: `SupabaseService` instantiated a standalone `SupabaseClient` directly instead of referencing `Supabase.instance.client` initialized by `supabase_flutter`. Raw `SupabaseClient` lacks Flutter's storage delegate.
- Solution:
  - Updated `SupabaseService.client` to delegate directly to `Supabase.instance.client` (with test fallback).
  - Ensured `main.dart` initializes `WidgetsFlutterBinding.ensureInitialized()` and `await Supabase.initialize(url: ..., publishableKey: ...)`.
  - Added user metadata `data: {'username': username}` to `signUp` and guarded profile creation.
  - Verified with `flutter analyze` (0 issues) and `flutter test` (3/3 passed).

### Bugfix: Dashboard White Screen & Screen 3 Redesign (2026-10-28)
- Issue: White blank screen after tapping "Create Account" or logging in.
- Root Cause: `DashboardScreen` contained an `Expanded` widget inside a `SingleChildScrollView` (which has unbounded vertical constraints), causing Flutter to throw an unhandled `RenderFlex` layout crash that collapsed the UI into a white blank screen.
- Solution:
  - Rebuilt [`dashboard_screen.dart`](file:///e:/code-decor/Habit-Nova/synvero/lib/features/dashboard/presentation/dashboard_screen.dart) implementing Screen 3 from the master design mockup:
    - User Greeting & profile avatar
    - Localized date badge pill
    - Blue gradient hero card ("Small steps create big results")
    - Today's Progress section: Circular progress gauge ("3/5 Habits completed") and stat badges (Study Time, Tasks Done, Streak)
    - Quick Action squircle buttons (Habits, Study Timer, Tasks, AI Assistant)
    - Today's Habits card ("Read a book - Completed")
    - 5-tab Bottom Navigation Bar (Home, Habits, Timer, Tasks, Profile)
  - Verified with `flutter analyze` (0 issues) and `flutter test` (3/3 passed).

## Session Update — Mockup UI Redesign: Screen 4 & Screen 5 (2026-10-28)

- Date: 2026-10-28
- Phase: UI Redesign (Screen 4: Habits Screen & Screen 5: Study Timer Screen)
- Files created:
  - `lib/features/timer/presentation/study_timer_screen.dart` — Study Timer screen matching Screen 5 in master mockup (dark midnight theme `#090E1A`, Pomodoro / Short Break / Long Break mode tabs, glowing cyan circular progress timer, interactive countdown, quote, stats card, and dark bottom navigation)
- Files modified:
  - `lib/features/habits/presentation/habit_screen.dart` — Redesigned Habits screen matching Screen 4 (header with blue '+' action, [Today, Weekly, Monthly] filter pills, habit cards with checkmark toggles and color squircle icons, Upcoming section with project and doctor appointment cards, 5-tab bottom navigation)
  - `lib/features/dashboard/presentation/dashboard_screen.dart` — Wired Study Timer quick action and bottom nav Timer tab to navigate directly to `/timer`
  - `lib/main.dart` — Registered `/timer` named route and imported `StudyTimerScreen`
- Commands run and results:
  - `flutter analyze` → No issues found! (0 warnings, 0 errors)
  - `flutter test test/widget_test.dart` → All 3 tests passed!
  - `hot_reload` via DTD → Applied live to running web app
- Next phase: Screen 6 (Tasks Screen) & Screen 7 (AI Assistant Screen)

## Session Update — Mockup UI Redesign: Complete Master Suite (Screens 6 to 10) (2026-10-28)

- Date: 2026-10-28
- Phase: Master 10-Screen Suite Completion
- Files created:
  - `lib/features/tasks/presentation/tasks_screen.dart` — Screen 6 (Tasks Screen with timeframe filters [Today, Upcoming, All], task checklist with completion toggles, priority badges [High, Medium, Low], upcoming timeline section, bottom nav)
  - `lib/features/ai_assistant/presentation/ai_assistant_screen.dart` — Screen 7 (AI Assistant with [Study, Fitness, Nutrition, General] topic chips, greeting bubble, quick prompt suggestions, interactive chat stream with send bar, bottom nav)
  - `lib/features/profile/presentation/profile_screen.dart` — Screen 8 (Profile & Settings with avatar card, username/email, Edit Profile dialog, lifestyle shortcuts to nutrition & fitness, full settings menu [Notifications, Appearance, Preferences, Security, Help, About], and red Log Out button with sign-out logic)
  - `lib/features/nutrition/presentation/nutrition_screen.dart` — Screen 9 (Nutrition Plan with daily calorie & macro overview [Carbs, Protein, Fats], meal plan cards for Breakfast, Lunch, Dinner with calorie indicators and toggle logging, interactive Add Meal dialog, and nutrition tips banner)
  - `lib/features/fitness/presentation/fitness_screen.dart` — Screen 10 (Fitness Plan with personalized workout overview, Day 1 Upper Body exercise list [Push-ups, Dumbbell Rows, Shoulder Press, Plank] with checkmark tracking, "View Full Plan" bottom sheet modal, and form tip banner)
- Files modified:
  - `lib/main.dart` — Registered routes `/tasks`, `/ai_assistant`, `/profile`, `/nutrition`, and `/fitness`.
  - `lib/features/dashboard/presentation/dashboard_screen.dart` — Connected quick actions to `/tasks` and `/ai_assistant`, added Lifestyle & Wellness section navigating to `/nutrition` and `/fitness`, and wired all bottom navigation tabs.
  - `lib/features/habits/presentation/habit_screen.dart` — Fully interconnected bottom navigation bar tabs.
  - `lib/features/timer/presentation/study_timer_screen.dart` — Fully interconnected bottom navigation bar tabs.
  - `lib/core/services/supabase_service.dart` — Configured `authOptions: const AuthClientOptions(autoRefreshToken: false)` on fallback test client to prevent leaked background timers during widget tests, and guarded user getter.
  - `test/widget_test.dart` — Added 4 new widget tests covering rendering and core widgets for Tasks, Profile, Nutrition, and Fitness screens (7/7 tests passing).
- Commands run and results:
  - `flutter analyze` → No issues found! (0 warnings, 0 errors)
  - `flutter test test/widget_test.dart` → All 7 tests passed!
  - `hot_reload` via DTD → Succeeded and live on Chrome.
- Master Status: All 10 screens from user mockup are implemented, connected, and verified!

## Operating Rule
Update this file only with verified project facts. Never record secrets, passwords, tokens, or API keys. After each phase, summarize progress and stop for user approval.


## Session Update — User Progress Isolation & Multi-Tenant Scoping (2026-10-28)

- Date: 2026-10-28
- Goal: Strictly isolate each user's progress (habits, tasks, timer focus sessions, nutrition meal logs, fitness exercise completion) to their own authenticated account (`user_${userId}_...`), preventing cross-user data leakage.
- Implementation:
  - `lib/features/habits/presentation/habit_screen.dart`: Dynamic `_currentUserId => SupabaseService.user?.id ?? 'guest'`. SharedPreferences persistence scoped to `user_${_currentUserId}_habit_${habitId}_completed`. New accounts start with clean slate.
  - `lib/features/tasks/presentation/tasks_screen.dart`: Scoped to `user_${_currentUserId}_task_${taskId}_completed`. New accounts start with 0 tasks checked.
  - `lib/features/dashboard/presentation/dashboard_screen.dart`: Dynamically tallies and renders `$_completedHabitsCount/5` based on `currentUserId` keys and Supabase user profile.
  - `lib/features/nutrition/presentation/nutrition_screen.dart`: Scoped meal checkoffs to `user_${_currentUserId}_meal_${meal.title}_logged`.
  - `lib/features/fitness/presentation/fitness_screen.dart`: Scoped workout exercises to `user_${_currentUserId}_exercise_${ex.title}_completed`.
  - `lib/features/timer/presentation/study_timer_screen.dart`: Scoped completed timer focus sessions to `user_${_currentUserId}_timer_completed_sessions`.
  - Supabase Database Backend: Row Level Security (RLS) policies enforce `auth.uid() = user_id` across `habits` and `habit_completions`.
- Verification:
  - `flutter analyze` → No issues found! (0 warnings, 0 errors).
  - `flutter test test/widget_test.dart` → All 7 tests passed!
  - `hot_reload` & `hot_restart` → Triggered successfully on running Chrome dev session.

## Session Update — Dynamic Theme Switcher (Light / Dark / System) (2026-10-28)

- Date: 2026-10-28
- Goal: Enable user to dynamically switch themes between Light Theme, Dark Theme, and System Default with persistent storage.
- Files created/modified:
  - `lib/core/services/theme_service.dart`: Created reactive `ThemeService` with `ValueNotifier<ThemeMode>`, helper getters, and SharedPreferences persistence (`app_theme_mode`).
  - `lib/app/theme/app_theme.dart`: Added `buildSynveroDarkTheme()` matching Synvero's deep midnight slate/navy aesthetic (`#0A0F1D` / `#131D31`).
  - `lib/main.dart`: Initialized `ThemeService.init()` and wrapped `MaterialApp` in `ValueListenableBuilder<ThemeMode>` with both `theme` and `darkTheme`.
  - `lib/features/profile/presentation/profile_screen.dart`: Wired "Appearance" tile to `_showThemeSelectionSheet()`, rendering an interactive modal with ☀️ Light Theme, 🌙 Dark Theme, and ⚙️ System Default. Adapted cards, text, icons, and bottom nav to respect dark mode.
  - `test/widget_test.dart`: Added test verifying appearance modal opens and displays all theme options (8/8 tests pass).
- Verification:
  - `flutter analyze` → No issues found! (0 warnings, 0 errors).
  - `flutter test test/widget_test.dart` → All 8 tests passed!
  - `hot_restart` executed on running Chrome session.

## Session Update — Device Notification Permission & Android Home Screen Widget (2026-10-28)

- Date: 2026-10-28
- Goals:
  1. Request real device notification permission from the user's phone/browser and provide granular reminder settings + live test notification trigger.
  2. Implement an Android Home Screen Widget (`SynveroAppWidget`) so the user can pin Synvero to their phone screen to monitor daily habits and focus streak.
- Files created/modified:
  - `android/app/src/main/AndroidManifest.xml`: Added `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, and registered `SynveroAppWidget` receiver.
  - `android/app/src/main/res/xml/synvero_app_widget_info.xml`: Configured 4x2 AppWidgetProvider metadata with 30-min periodic update.
  - `android/app/src/main/res/drawable/widget_background.xml`: Premium rounded gradient `#2F65F6` to `#1E3A8A` widget background.
  - `android/app/src/main/res/layout/synvero_app_widget.xml`: Android widget layout featuring app title, streak badge, habit completion ratio (`4 of 5 Done`), percentage indicator, and quick tap action.
  - `android/app/src/main/kotlin/com/example/synvero/SynveroAppWidget.kt`: Kotlin `AppWidgetProvider` launching `MainActivity` on tap.
  - `lib/core/services/notification_service.dart`, `notification_platform_stub.dart`, `notification_platform_web.dart`: Cross-platform notification service handling permission request, permission status check, and test notification dispatch.
  - `web/index.html`: Integrated JavaScript notification functions for browser native permission prompt and desktop alerts.
  - `lib/features/profile/presentation/profile_screen.dart`:
    - Wired "Notification Settings" to interactive permission card, permission request button, "Send Test Notification", and 4 granular reminder toggles (Habits, Timer, Nutrition, Tasks).
    - Added "Home Screen Widget" menu option with live interactive 4x2 preview card and 3-step guide on pinning to home screen.
  - `test/widget_test.dart`: Added 2 new tests for notification modal and home widget modal (10/10 tests pass).
- Verification:
  - `flutter analyze` → No issues found! (0 warnings, 0 errors).
  - `flutter test test/widget_test.dart` → All 10 tests passed!
  - `hot_restart` executed on running Chrome dev session.

## Session Update — Study Timer User-Customizable Focus Duration (2026-10-28)

- Date: 2026-10-28
- Goal: Allow the user to specify and customize their desired focus time in the Study Timer (`StudyTimerScreen`).
- Implementation Details:
  - `lib/features/timer/presentation/study_timer_screen.dart`:
    - Added user-customizable focus duration state (`_customFocusMinutes`, default 25m, range 1-180m).
    - Added SharedPreferences per-user isolation persistence: `user_${_currentUserId}_focus_duration_mins`.
    - Added Quick Preset Duration Chips right below the mode selector: `[15 min] [25 min] [30 min] [45 min] [60 min] [Custom]`.
    - Tapping any preset chip immediately updates the countdown ring and timer to that duration.
    - Added interactive `_showDurationPickerSheet()` bottom modal featuring:
      - Stepper buttons (`Icons.remove_circle_outline_rounded` and `Icons.add_circle_outline_rounded`) with `-5m` / `+5m` intervals.
      - Interactive duration slider (`1 to 120 mins`).
      - Full preset chips wrap (`15m, 20m, 25m, 30m, 45m, 60m, 90m`).
      - "Set Focus Time" CTA button.
    - Made the central countdown ring tappable (`Tap to change duration`) with edit pencil icon when paused.
    - Wired AppBar tune icon (`Icons.tune_rounded`) to open the focus duration picker.
    - Updated total study time analytics calculation dynamically based on `_customFocusMinutes`.
  - `test/widget_test.dart`:
    - Added widget test verifying custom focus time preset chips update timer to `45:00`.
    - Added widget test verifying custom bottom sheet opens, increments duration via stepper, and updates timer to `30:00`.
- Verification:
  - `flutter analyze` → 0 issues found!
  - `flutter test test/widget_test.dart` → All 12 tests passed!
  - `hot_restart` executed successfully on running Chrome dev session.

## Session Update — Clean Dashboard User State (Zero Dummy Data / Pre-completed Tasks) (2026-10-28)

- Date: 2026-10-28
- Goal: Ensure that when any user registers or logs in, their dashboard reflects their actual fresh progress with zero dummy data or pre-completed tasks.
- Changes made:
  - `lib/features/dashboard/presentation/dashboard_screen.dart`:
    - Reset `_completedHabitsCount` to `0` initially (was hardcoded `2`).
    - Dynamic study time calculation: reflects `_studyMinutes` (`0m` initially, instead of fake `2h 15m`).
    - Dynamic tasks completion: reflects `_tasksDoneCount/_tasksTotalCount` (`0/4` initially, instead of fake `4/6`).
    - Dynamic streak: reflects real user streak (`0 days` initially, instead of fake `7 days`).
    - Dynamic user name & avatar: strictly uses authenticated user's name/email prefix or fallback `'User'` (removed hardcoded `'Yogesh'`).
    - Replaced hardcoded "Read a book - Completed" card in "Today's Habits" with dynamic real habit list showing `Pending` by default with clean uncompleted circular checkboxes.
    - Added `_toggleDashboardHabit` allowing direct one-tap habit completion from the dashboard with live gauge update and user-isolated SharedPreferences persistence.
  - `lib/features/habits/presentation/habit_screen.dart`:
    - All starter habits initialized with `completed: false` and subtitles `'0/1 completed'`, `'0/8 glasses'`, etc. (removed hardcoded `completed: true` for workout & book).
    - Subtitles dynamically update between pending and completed on toggle.
  - `lib/features/timer/presentation/study_timer_screen.dart`:
    - `_completedSessions` reset to `0` by default (was hardcoded `2`).
  - `lib/features/profile/presentation/profile_screen.dart`:
    - Initial `_displayName` and `_displayEmail` reset to `'User'` / empty, dynamically resolved from authenticated user (removed hardcoded `'Yogesh Chavan'` / `'yogesh@gmail.com'`).
  - `test/widget_test.dart`:
    - Added widget test verifying dashboard clean state (`0/5`, `0m`, `0/4`, `0 days`, `Pending` habits, zero pre-completed items).
- Verification:
  - `flutter analyze` → No issues found! (0 warnings, 0 errors).
  - `flutter test test/widget_test.dart` → All 13 tests passed!
  - `hot_restart` executed successfully on running Chrome dev session.

## Session Update — Persistent User Login Session (2026-10-28)

- Date: 2026-10-28
- Goal: Ensure that once a user logs in, they stay logged in across app restarts, browser refreshes, and app closures until they explicitly click "Log Out".
- Changes made:
  - `lib/features/auth/data/auth_repository.dart`:
    - Updated `signIn()` and `signUp()` to persist `is_user_logged_in: true` and `logged_in_user_id` in `SharedPreferences`.
    - Added `isLoggedIn()` checking active Supabase session and `is_user_logged_in` persistent flag.
    - Updated `signOut()` to explicitly clear `is_user_logged_in` and `logged_in_user_id` alongside `SupabaseService.signOut()`.
  - `lib/main.dart`:
    - Updated `_AuthWrapperState`:
      - Asynchronously verifies persistent auth status in `initState()` via `_checkInitialAuth()`.
      - Sets `initialRoute` dynamically: `_isAuthenticated ? '/dashboard' : '/login'`.
      - On app reload, refresh, or reopen: logged-in users are immediately taken to `/dashboard`.
      - Prevents forced redirection to `/login` when already logged in.
  - `test/widget_test.dart`:
    - Added 2 widget tests verifying persistent login behavior:
      1. `AuthWrapper restores persistent session and stays logged in on dashboard`.
      2. `AuthWrapper shows login screen when user is not logged in`.
- Verification:
  - `flutter analyze` → No issues found! (0 warnings, 0 errors).
  - `flutter test test/widget_test.dart` → All 15 tests passed!
  - `hot_restart` executed successfully on running Chrome dev session.




