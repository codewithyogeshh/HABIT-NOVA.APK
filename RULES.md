# Synvero — Development Rules

## 1. Mandatory Workflow
1. Read `PRD.md`, `ARCHITECTURE.md`, `RULES.md`, `PHASES.md`, and `MEMORY.md` before beginning a new development session.
2. Inspect the existing project and Git status before modifying files.
3. Work only on the phase explicitly requested by the user.
4. State the goal and planned files before editing.
5. Do not implement future phases pre-emptively.
6. After changes, run appropriate checks and report actual results.
7. Update `MEMORY.md` with verified progress and known issues.
8. Stop and wait for user approval before moving to the next phase.

## 2. Preserve the Existing Project
- Do not replace the entire `lib/` folder or regenerate the project without approval.
- Preserve uncommitted user changes.
- Reuse existing services, models, routes, themes, and state management when reasonable.
- Avoid duplicate Supabase clients, duplicate authentication flows, and duplicate tables.
- Do not remove working features to make a new feature easier.
- If a breaking change is necessary, explain it and ask first.

## 3. Code Quality
- Use null safety and clear, descriptive names.
- Keep widgets focused and extract reusable components where useful.
- Separate UI from data access and business logic where practical.
- Follow the current project's formatting and conventions.
- Avoid unnecessary dependencies and unnecessary abstractions.
- Verify package versions and APIs before using them.
- Never provide pseudocode when complete code is requested.
- Do not invent files, functions, or APIs that do not exist in the project.
- Handle loading, empty, success, and error states.

## 4. Dependencies and Commands
- Do not add packages without explaining why.
- Do not upgrade all dependencies just to resolve one issue.
- Run `flutter pub get` when dependencies change.
- Run `dart format` on modified Dart files where appropriate.
- Run `flutter analyze` and relevant tests after changes.
- Do not claim checks passed unless they were actually run.
- Never run destructive commands, reset Git, delete user data, or apply remote database migrations without explicit approval.

## 5. Error Handling
- Validate inputs at UI boundaries and again on trusted backend boundaries.
- Show understandable user-facing messages.
- Do not swallow exceptions silently.
- Do not expose stack traces, tokens, secrets, or internal database details to end users.
- Log only information needed for debugging and avoid sensitive content.
- For a reported bug, reproduce or inspect the exact error and relevant code before changing anything.

## 6. Supabase and Data Security
- Never place the service-role key in Flutter code.
- Never embed an AI provider secret in the app.
- Treat client-side `.env` values as extractable from a compiled mobile app.
- Use authenticated user identity and enforce RLS for every user-owned table.
- Add and test appropriate `SELECT`, `INSERT`, `UPDATE`, and `DELETE` policies.
- Never rely only on hiding UI controls for security.
- Do not expose another user's profile, habits, tasks, study history, or chat messages.
- Use migrations for schema changes and ask before applying them to a connected project.
- Do not fabricate successful authentication or database responses.

## 7. AI Assistant Boundaries
- Route AI requests through a trusted backend.
- Validate input, enforce authorization, and consider rate limits and usage costs.
- Do not claim AI content is always correct.
- Study mode should explain concepts and encourage learning.
- Fitness and nutrition responses must be general wellness guidance, not diagnosis or treatment.
- Encourage professional support for medical concerns or high-risk situations.
- Do not expose system prompts, credentials, or private data in client-visible logs.
- Treat user-provided text and AI output as untrusted input.

## 8. UI and Accessibility
- Follow `PHASES.md` for the visual system.
- Keep controls usable on small Android screens and with the keyboard open.
- Use readable contrast, clear labels, and accessible tap targets.
- Avoid nonfunctional buttons. Clearly mark features not yet implemented.
- Keep layouts responsive and provide useful loading/empty/error states.

## 9. Final Report Format
After each phase, report:
- What changed.
- Files created/modified.
- Commands actually run and results.
- Manual steps required.
- Remaining bugs or risks.
- Whether the phase is complete.
- The exact next phase, without starting it.
