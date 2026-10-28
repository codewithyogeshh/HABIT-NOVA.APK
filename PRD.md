# Synvero — Product Requirements Document (PRD)

## 1. Product Overview
**Product name:** Synvero  
**Tagline:** Everything Working in Sync.  
**Platform:** Android first, built with Flutter and Dart.  
**Backend:** Supabase.  
**Product vision:** An all-in-one personal growth app that helps users build habits, study with focus, organize tasks, improve fitness, plan meals, and get AI-powered guidance.

## 2. Target Users
- Students who need study sessions, focus timers, revision support, and reminders.
- People who want to build consistent daily habits.
- Users who want basic workout planning and general nutrition ideas.
- People who want one place to manage goals and daily routines.

## 3. Core Features
### Authentication and Profile
- Sign up with username, email, and password.
- Log in and log out.
- Persist sessions securely through Supabase Auth.
- Support email confirmation and password recovery where configured.
- Store profile information in a user-owned profile table.
- Show the logged-in username and today's local date on the dashboard.

### Home Dashboard
- Friendly greeting, username, and current date.
- Today's habit progress and task summary.
- Study time summary and quick actions.
- Clear navigation to core modules.
- Useful loading, empty, and error states.

### Habit Tracker
- Create, edit, archive/delete habits.
- Mark habits complete for a given local calendar date.
- Show streaks and daily/weekly completion summaries.
- Prevent duplicate completion records for the same habit and date.

### Study Timer and Focus Mode
- Configurable focus and break durations.
- Start, pause, resume, and reset.
- Focus-mode interface.
- Save completed sessions and show study statistics.
- Calculate remaining time using timestamps/elapsed time so the timer remains accurate after app backgrounding.

### Tasks and Reminders
- Create, edit, complete, and delete tasks.
- Due date, time, and priority.
- Local notifications and permission handling.
- Recurring reminders only where supported and tested.
- Synchronize task data with Supabase.

### AI Personal Assistant
- Modes: Study, Fitness, Nutrition, General.
- Study explanations, summaries, quizzes, and study plans.
- General workout routine suggestions.
- General meal-planning and nutrition suggestions.
- Loading, retry, and error states.
- Use a trusted backend (for example, a Supabase Edge Function) to call the AI provider.
- Never embed AI provider secrets in Flutter client code.
- Treat AI output as guidance, not as medical diagnosis or professional care.

### Settings
- View/update username and preferences.
- Notification preferences.
- Logout.
- Theme setting if supported by the existing architecture.

## 4. MVP Priorities
**P0 — Required**
1. Existing project audit and stable Flutter app foundation.
2. Login and signup UI.
3. Supabase Auth and secure profile handling.
4. Home dashboard with username and today's date.
5. Habit CRUD and completion tracking.
6. Study timer.
7. Task management and local reminders.
8. Secure AI chat integration.
9. Tests, security review, and Android release preparation.

**P1 — Later improvements**
- Advanced analytics and charts.
- Habit categories and custom schedules.
- Export and backup options.
- Additional themes and personalization.

## 5. Non-Functional Requirements
- Responsive on common Android screen sizes.
- Maintainable, modular Dart code.
- Respect user privacy and minimize collected data.
- Use Supabase Row Level Security (RLS) for user-owned data.
- Provide understandable validation and error messages.
- Avoid claiming success when an operation fails.
- Support offline local timer behavior where feasible; network-backed features require connectivity.

## 6. Out of Scope for Initial MVP
- Medical diagnosis or treatment.
- Guaranteed nutritional or fitness outcomes.
- Public social feed.
- Payments/subscriptions unless explicitly approved later.
- Background AI execution without user interaction.

## 7. Acceptance Criteria
- A new user can create an account and sign in once backend configuration is complete.
- A signed-in user sees only their own records.
- Users can create and complete habits and tasks.
- Study sessions are recorded accurately.
- Task notifications work on a real Android device after permissions are granted.
- AI requests go through a secure backend; no provider secret is shipped in the app.
- The app passes `flutter analyze` and relevant tests, with remaining issues documented.
