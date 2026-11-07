# Gemini AI Proxy (Supabase Edge Function)

A secure server-side proxy for Google Gemini AI used by the HabitNova / Synvero
Flutter app. The Gemini API key is stored **only here on the server**, never in
the app, so it cannot be extracted from the APK.

## What the app does

`GeminiAIService.generateResponse(...)` calls this function first. If the
function is deployed and healthy, real-time Gemini answers are returned. If not
(e.g. not deployed yet), the app gracefully falls back to the offline
`AIResponseEngine`, so the assistant still works.

## Deploy (one-time)

Requires the [Supabase CLI](https://supabase.com/docs/guides/cli) and a linked
project (your project is already configured in the app via `supabase_config.dart`).

```bash
# 1. Link this repo to your Supabase project
supabase link --project-ref stazogqvkrayckdigfwz

# 2. Store your Gemini API key as a server-side secret (never commit it)
supabase secrets set GEMINI_API_KEY=AIzaSyYOUR_KEY_HERE

# 3. Deploy the function
supabase functions deploy gemini-proxy
```

The function is then live at:

```
https://stazogqvkrayckdigfwz.supabase.co/functions/v1/gemini-proxy
```

## Verify

In the app, open AI Assistant and send a message. If the proxy is live you get
real-time Gemini answers. If it isn't reachable, you'll get offline-engine
answers (and a debug log line: `Gemini proxy returned HTTP ...`).

## Security notes

- The Gemini key lives only in `GEMINI_API_KEY` — keep it out of the app and out
  of git.
- The function is intentionally open (no auth check) so the app can call it
  without a login. To lock it down, add a JWT verification against the
  `Authorization: Bearer` header before deploying to production.
- The `GeminiAIService` also still supports an *optional* user-entered direct
  key (stored in shared preferences) as a fallback if you prefer not to use the
  proxy.
