# Synvero — Architecture

## 1. Architecture Principles
- Inspect and extend the existing project before restructuring it.
- Prefer the project's existing working libraries and conventions.
- Avoid duplicate clients, duplicate routing systems, or parallel implementations.
- Keep UI, state, business logic, and data access separated where practical.
- Build one approved phase at a time.

## 2. Technology
- Flutter / Dart.
- Supabase Auth and PostgreSQL.
- Supabase Row Level Security (RLS).
- Riverpod and GoRouter only if appropriate for the current project; do not add them if an existing architecture already works.
- Local notifications for task reminders, with Android permissions and exact-alarm limitations handled explicitly.
- Supabase Edge Function or another trusted backend for AI provider calls.

Check installed package versions and current APIs before editing `pubspec.yaml`.

## 3. Suggested Folder Structure
Adapt this to the existing project rather than replacing it blindly.

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme/
      app_theme.dart
      app_colors.dart
  core/
    config/
    errors/
    utils/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    dashboard/
      presentation/
    habits/
      data/
      domain/
      presentation/
    study/
      data/
      domain/
      presentation/
    tasks/
      data/
      domain/
      presentation/
    assistant/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
```

## 4. Data Flow
1. User interacts with a screen/widget.
2. A provider/controller manages loading, success, and error state.
3. A repository/service performs business or data operations.
4. Supabase client accesses authenticated user-owned data.
5. PostgreSQL RLS verifies record access.
6. Results return through the repository to state and UI.

AI request flow:
Flutter UI → authenticated request → backend function → AI provider → validated response → Flutter UI.

Never call a provider using a secret embedded in the Flutter client.

## 5. Proposed Database
Finalize schema and migrations during the backend phase, after auditing existing tables.

### profiles
- `id uuid primary key references auth.users(id)`
- `username text`
- `created_at timestamptz`
- `updated_at timestamptz`

### habits
- `id uuid primary key`
- `user_id uuid references auth.users(id)`
- `title text`
- `description text nullable`
- `schedule jsonb` or another explicitly chosen schedule representation
- `created_at timestamptz`
- `updated_at timestamptz`
- Optional `archived_at timestamptz`

### habit_completions
- `id uuid primary key`
- `user_id uuid references auth.users(id)`
- `habit_id uuid references habits(id)`
- `completion_date date`
- `completed_at timestamptz`
- Unique constraint on `(habit_id, completion_date)`.

### tasks
- `id uuid primary key`
- `user_id uuid references auth.users(id)`
- `title text`
- `notes text nullable`
- `due_at timestamptz nullable`
- `priority text`
- `completed_at timestamptz nullable`
- `created_at timestamptz`
- `updated_at timestamptz`

### study_sessions
- `id uuid primary key`
- `user_id uuid references auth.users(id)`
- `started_at timestamptz`
- `ended_at timestamptz nullable`
- `duration_seconds integer`
- `session_type text`
- `created_at timestamptz`

### chat_messages (optional; decide before implementation)
- `id uuid primary key`
- `user_id uuid references auth.users(id)`
- `conversation_id uuid`
- `role text`
- `content text`
- `created_at timestamptz`

Use migrations, foreign keys, indexes, constraints, and RLS. Do not run migrations against a real project without explicit approval.

## 6. Security
- Use only the Supabase publishable/anon client key in the app as appropriate; secure every exposed table with RLS.
- Never ship the Supabase service-role key or AI provider key in the client.
- Do not trust a client-provided `user_id`; derive identity from the authenticated session on the backend.
- Validate input and apply rate limits to AI endpoints.
- Do not log passwords, access tokens, API keys, or sensitive chat content.
- Ensure profile creation/update policies only permit the matching authenticated user.
- Use environment configuration appropriately; remember Flutter client values are not secret merely because they are in a `.env` file.

## 7. Date and Time
- Store timestamps as UTC (`timestamptz`) where appropriate.
- Render today's date using the device's local timezone.
- Store habit completion as a calendar date with a clearly defined local-date strategy.
- Schedule notifications with timezone and Android OS behavior in mind.

## 8. Testing
- Unit tests for validation, streak logic, and timer calculations.
- Widget tests for login/signup and main interactions.
- Repository/service tests where practical.
- Manual Android tests for notifications and lifecycle behavior.
- Verify RLS with different authenticated users before release.
