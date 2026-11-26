# Contributing to HabitNova / Synvero

A Flutter (Dart) habit tracker with study timer, tasks, fitness/nutrition guides,
AI assistant, squads and leaderboard — backed by Supabase and deployed as a web
build on Cloudflare.

This guide is for working on the project as a small team (two developers).

---

## 1. Prerequisites

| Tool | Version used to verify this repo |
| --- | --- |
| Flutter | 3.50.1 (stable) |
| Dart | 3.14.0 (bundled with Flutter 3.50.1) |
| Android SDK | Only needed to build/run the APK on a device |
| Supabase CLI | Only needed to deploy `supabase/functions` or run migrations |

`pubspec.yaml` requires Dart `^3.13.7`, so an older Flutter will not resolve
dependencies — update Flutter before debugging "version solving failed".

## 2. First-time setup

```bash
git clone https://github.com/codewithyogeshh/HABIT-NOVA.APK.git
cd HABIT-NOVA.APK
git checkout -b feat/<your-name>-<short-description>
flutter pub get
flutter analyze
flutter test
```

Run the app:

```bash
flutter devices          # confirm a device/emulator is visible
flutter run              # Android device or Chrome
flutter run -d chrome    # web build (some native features are stubbed)
```

Notes:

- The first `flutter run` on Android needs an emulator or a USB device with
  developer mode enabled.
- Notification, alarm, widget and app-blocker features use Android platform
  channels. Web builds stub them out (`*_platform_web.dart`), so test those
  changes on an Android device, not in Chrome.
- The project is Android-first; iOS/macOS/Windows/Linux folders exist but are
  not part of the current test surface.

## 3. Baseline health (verified)

- `flutter analyze` → **49 issues, all `info`**, all the same lint: Flutter 3.50
  deprecated `package:flutter/material.dart` in favour of
  `package:material_ui/material_ui.dart`. No errors or warnings. Leave the
  migration for a dedicated PR rather than mixing it into feature work.
- `flutter test` → **19/19 tests pass**.
- `test/widget_test.dart` is the only test file. Widget tests mock Supabase and
  shared preferences; add tests beside it.

## 4. Repository map

```text
lib/
  main.dart                     App bootstrap, service init, AuthWrapper + named routes
  app/theme/                    Colors and light/dark themes
  core/config/                  Supabase URL + publishable (anon) key
  core/navigation/              Root shell (5-tab sliding pill nav), page transitions
  core/services/                Business logic: habits, tasks, timer, notifications,
                                squads, leaderboard, gamification, ads, language, theme
  core/widgets/                 Shared UI (glass card, splash, gooey notifications, logo)
  features/<feature>/
    data/                       Repositories, models, external service clients
    domain/                     Pure Dart logic (e.g. AIResponseEngine)
    presentation/               Screens and feature widgets
supabase/
  migrations/                   profiles, habits, habit_completions (with RLS)
  functions/gemini-proxy/       Edge Function that holds the Gemini key server-side
android/app/src/main/kotlin/    Native widget, usage stats, app-blocker accessibility service
test/                           Widget/unit tests
```

Architecture rules for this codebase live in `ARCHITECTURE.md`, product scope in
`PRD.md`, and the project's own development rules in `RULES.md` — read `RULES.md`
before changing behaviour. `MEMORY.md` is the AI session log; treat it as
history, not source of truth.

## 5. Working as two people

1. **One branch per piece of work**, cut from an up-to-date `main`:
   `feat/…`, `fix/…`, `refactor/…`, `chore/…`, `docs/…`.
2. **Pull before you push**: `git pull --rebase origin main`.
3. **Keep PRs small and single-purpose.** A PR that reformats 40 files hides the
   one line that matters.
4. **At least one review** from the other person before merging to `main`.
   Since the two of you are the whole team, agree on one rule: never push
   directly to `main`; always go through a PR even if you approve it yourself.
5. **Protect `main`** in GitHub → Settings → Branches: require a PR and one
   approval. That prevents accidental force-pushes over each other's work.
6. **Resolve conflicts in `pubspec.lock` by regenerating**, not by hand-editing:
   take either side, then run `flutter pub get` and commit the result.
7. **Do not both edit `MEMORY.md` in the same PR.** It conflicts on almost every
   line; append your session entry last, right before merging.
8. **Commit messages** follow the existing conventional style, e.g.
   `feat: real-time squads with real users`, `fix(deploy): remove conflicting _redirects`.

## 6. Security rules (non-negotiable)

- The Supabase **anon/publishable key** in `lib/core/config/supabase_config.dart`
  is public by design; the database is protected by RLS policies in
  `supabase/migrations/`. Any new user-owned table **must** ship with
  `ENABLE ROW LEVEL SECURITY` and per-user policies in the same PR.
- **Never** commit a `service_role` key, a Gemini/AI provider key, or any
  password. The AI key belongs only in the Supabase secret `GEMINI_API_KEY`
  consumed by `supabase/functions/gemini-proxy`.
- New social/leaderboard/squad data must not expose another user's profile,
  habits, tasks, study history or chat messages.
- Validate at the UI boundary *and* at the backend boundary; never trust a
  client-supplied `user_id`.

### Known security issue to fix (do not ignore)

`lib/features/ai_assistant/data/gemini_ai_service.dart` ships a base64-encoded
default Gemini API key in the client (`_defaultApiKey`) and calls
`generativelanguage.googleapis.com` directly before trying the proxy. Base64 is
encoding, not encryption — the key is extractable from the APK, which is exactly
what `RULES.md` §7 and `supabase/functions/gemini-proxy/README.md` forbid.

Required remediation, in order:

1. **Revoke/rotate that Gemini key** in Google AI Studio (owner's account) —
   assume it is public.
2. Remove `_defaultApiKey` and the direct-call path, so
   `generateResponse()` uses the proxy then the offline `AIResponseEngine`.
3. Remove the "user supplies their own key" UI path if it still exists, or keep
   it only as an explicit opt-in with a clear warning.

The same pattern appears for Firebase: `lib/core/services/leaderboard_service.dart`
and `lib/core/services/squad_service.dart` both hardcode the same
`AIza…` Firestore Web API key and write to a Firestore project
(`taskflow-c57d8`) outside Supabase. At minimum, restrict that key by HTTP
referrer/app in Google Cloud Console; better, move squad/leaderboard data into
Supabase tables with RLS so one backend and one security model applies.

## 7. Repository hygiene

- **Two 80 MB APKs are committed** (`habit-nova-release.apk` and
  `apk/habit-nova-release.apk`) and several historical copies live in Git
  history. That is why `.git` alone is ~69 MB and clones are slow.
  - From now on, publish builds as **GitHub Releases** instead of commits.
  - Add `*.apk` to `.gitignore` and `git rm --cached` the tracked copies.
  - Rewriting history (`git filter-repo`) is optional but must be coordinated:
    both of you re-clone afterwards. Never do it mid-PR.
- Do not commit `.dart_tool/`, `build/`, IDE folders, or local `.env` files.
- Flutter 3.50 re-resolves three transitive pins (`meta`, `test_api`, `listen`)
  in `pubspec.lock`. Decide as a team whether to accept that bump; don't leave
  the lockfile half-updated in unrelated PRs.

## 8. Definition of done for a PR

- [ ] `flutter analyze` introduces no new issues (info-only is the current bar).
- [ ] `flutter test` passes.
- [ ] New user-owned data has RLS policies and a migration in the same PR.
- [ ] Loading, empty, success and error states handled; nothing silently swallowed.
- [ ] Tested on an Android device if it touches notifications, timers,
      widget, app blocker or other platform channels.
- [ ] Screenshots or a short clip in the PR description for UI changes.

## 9. Good first contributions

Ordered by value and risk:

1. **Security**: remove the embedded Gemini key path (see §6) after the owner
   rotates the key.
2. **Repo hygiene**: untrack the APKs, add `*.apk` to `.gitignore`, document the
   release process.
3. **Deduplicate the Firestore key** into one config constant instead of three
   copies, then restrict it in Google Cloud Console.
4. **CI**: add a GitHub Actions workflow running `flutter analyze` and
   `flutter test` on every PR (there is no `.github/` yet). This is what makes
   two-person work safe.
5. **Consistency**: the app is labelled "HabbitNova" in `AndroidManifest.xml` and
   `MaterialApp.title` but documented as "Synvero", and the package id is still
   `com.example.synvero`. Pick one product name and one application id before a
   release.
6. **Tests**: study-timer accuracy after backgrounding, streak calculation
   boundaries, and habit-completion date handling are untested logic with real
   bug potential.
7. **Flutter 3.50 migration**: `material.dart` → `material_ui` as one dedicated,
   mechanical PR.

## 10. Releasing a new build (without asking users to reinstall)

The app checks a small JSON manifest for a newer build and shows an in-app
"Update available" card. Tapping **Update now** opens the APK download; Android
installs it *over* the existing app, so habits, streaks and login are preserved.

### How the check works

| Piece | Location |
| --- | --- |
| Manifest URL + timings | `lib/core/config/app_update_config.dart` |
| Version compare / fetch | `lib/core/services/app_update_service.dart` |
| Premium popup UI | `lib/core/widgets/app_update_overlay.dart` |
| The manifest itself | `version.json` (repo root, served via raw GitHub) |

- Runs ~3 seconds after startup and again when the app returns to foreground.
- At most one network call per 6 hours; "Later" snoozes it for 24 hours.
- Android only (`package_info_plus` reads the real installed version).
- Any failure (offline, 404, bad JSON) is ignored silently — the app still opens.
- Set `min_supported_build` in `version.json` to force an update; the popup then
  has no "Later" button.

### Steps for every release

1. Bump **both** parts of the version in `pubspec.yaml` — `version: 1.2.0+3`.
   The build number (after `+`) must always increase.
2. Build: `flutter build apk --release`.
3. Upload the APK somewhere stable and put that exact URL in `version.json`
   as `apk_url` (a GitHub Release asset is recommended over a repo file, because
   release assets keep their name and never bloat the git history).
4. Update `version.json`: `latest_version`, `latest_build` (must equal the new
   build number), `notes`, `released_at`. Commit and push `version.json`.
5. Users on older builds now see the popup next time they open the app.

> Publish the APK *before* committing `version.json`, otherwise users are told
> about an update that isn't downloadable yet.

### Two rules you must never break

1. **Never change `applicationId`** (`android/app/build.gradle.kts`). A different
   id is treated by Android as a different app: the popup would install a second
   app instead of updating the existing one. Decide the final id *before* real
   users install it.
2. **Always sign releases with the same keystore.** A different signature makes
   Android refuse the update ("App not installed"). One-time setup:

   ```properties
   # android/key.properties  (git-ignored — never commit this file)
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

   Create the key once with `keytool -genkey -v -keystore upload-keystore.jks
   -keyalg RSA -keysize 2048 -validity 10000 -alias upload`, back up the `.jks`
   file and its passwords somewhere safe, and share them with your teammate
   through a password manager — **not** over chat or git.

   Until `android/key.properties` exists the release build falls back to the
   debug keystore, which changes per machine and will break in-place updates.

### Testing the popup locally

```bash
flutter build apk --dart-define=UPDATE_MANIFEST_URL=https://your-host/version.json
```

Point that URL at a manifest with a higher `latest_build` than the installed
version and reopen the app.
