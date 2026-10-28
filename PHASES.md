# Synvero — Design System and Development Phases

## 1. Brand and UI Direction
- Product: Synvero
- Tagline: Everything Working in Sync.
- Visual style: premium, modern, calm, minimal.
- Primary color: `#4361EE`
- Dark text: `#172033`
- Secondary text: `#667085`
- Main background: `#FFFFFF`
- Soft blue background: `#F3F6FF`
- Border: `#E5EAF5`
- Success: use a clear accessible green.
- Error: use a clear accessible red.
- Prefer rounded cards and fields, restrained shadows, consistent spacing, and clean typography.
- Do not use color alone to convey status.
- Use Material 3 components when compatible with the existing app.
- Use a simple original icon until a final logo is approved.

## 2. Core UI Patterns
- Use `SafeArea` and responsive layouts.
- Handle keyboard overlap on forms.
- Inputs must have labels, appropriate keyboard types, validation, and autofill hints.
- Passwords must support visibility toggles.
- Buttons need loading/disabled states during async operations.
- Provide empty, loading, success, and error states.
- Keep bottom navigation consistent once the main app shell is implemented.
- Dashboard top area should show the user's username and today's local date.
- Do not show fake social login or other nonfunctional actions.

## 3. Development Phases
Complete each phase individually. Stop after each phase and wait for approval.

### Phase 0 — Audit and Plan
- Inspect current Flutter files, dependencies, routes, theme, tests, Android config, Supabase setup, and Git status.
- Report existing functionality and risks.
- No changes until approved.

### Phase 1 — Login UI
- Implement only the login screen.
- Email and password inputs, validation, password visibility, loading/error UI.
- Reuse existing authentication if configured; never fake successful login.
- Test and stop.

### Phase 2 — Signup UI
- Username, email, password, confirm password.
- Validation and navigation between login and signup.
- Connect to Supabase only if existing setup is ready; otherwise clearly document missing configuration.
- Test and stop.

### Phase 3 — Supabase Auth and Profiles
- Configure/reuse Supabase client.
- Implement signup, login, logout, session restore, profile handling, and password recovery where configured.
- Create/review SQL migrations and RLS.
- Never expose privileged keys.
- Test auth flows and stop.

### Phase 4 — Home Dashboard
- Username and today's local date.
- Habit/task summaries, study-time summary, progress cards, and navigation.
- Use real data or honest empty states.
- Test and stop.

### Phase 5 — Habit Tracker
- Create, edit, archive/delete habits.
- Daily completion, history, streaks, and weekly summaries.
- Add constraints and RLS.
- Test date boundaries and duplicate completion behavior.

### Phase 6 — Study Timer and Focus Mode
- Configurable focus/break durations.
- Start, pause, resume, reset.
- Accurate timer after app backgrounding.
- Save completed study sessions and statistics.

### Phase 7 — Tasks and Reminders
- Task CRUD, due dates, priorities, completion.
- Local notifications, permissions, timezone handling, and Android-specific setup.
- Test on a physical device where possible.

### Phase 8 — AI Assistant
- Study, Fitness, Nutrition, and General modes.
- Secure backend function for provider calls.
- Loading/error/retry handling, input validation, rate limiting, and privacy-aware history.
- Never expose AI secrets in Flutter.

### Phase 9 — Profile, Settings, QA and Release
- Profile/preferences, logout, theme settings if supported.
- Regression tests, RLS verification, accessibility checks, Android build and release instructions.
- Document known limitations.

## 4. Phase Completion Gate
A phase is complete only when:
- Its acceptance criteria are addressed.
- Relevant analysis/tests have been run where possible.
- Any unverified behavior is explicitly documented.
- `MEMORY.md` is updated.
- The AI has stopped and is waiting for approval.
