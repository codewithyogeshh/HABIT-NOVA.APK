import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// ---------------------------------------------------------------------------
// Gemini API Proxy — Supabase Edge Function
// ---------------------------------------------------------------------------
// The Gemini API key lives ONLY here (server-side), set as the Supabase secret
// `GEMINI_API_KEY`. The Flutter app never contains the key; it calls this
// function instead, so the key can't be extracted from the APK.
//
// Deploy:
//   1. supabase secrets set GEMINI_API_KEY=your_key
//   2. supabase functions deploy gemini-proxy
// ---------------------------------------------------------------------------

interface GeminiRequest {
  prompt?: string;
  category?: string;
  userName?: string;
}

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";

// Models are tried in order until one succeeds. Keep these in sync with the
// models that exist on the Google Generative Language API.
const MODELS = [
  "gemini-3.5-flash",
  "gemini-3.5-flash-lite",
  "gemini-3.6-flash",
  "gemini-3-flash-preview",
  "gemini-3.7-flash",
  "gemini-3.8-flash",
];

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  if (!GEMINI_API_KEY) {
    return json(
      { error: "Server not configured: set the GEMINI_API_KEY secret." },
      500,
    );
  }

  let body: GeminiRequest;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const prompt = (body.prompt ?? "").trim();
  const category = (body.category ?? "General").trim();
  const name = (body.userName ?? "Friend").trim();

  if (!prompt) {
    return json({ error: "Missing prompt" }, 400);
  }

  const systemInstruction =
    "You are HabbitNova AI, a friendly, encouraging personal assistant and " +
    `habit companion for ${name}. ` +
    "Your app focuses on habit building, focus study, task management, fitness, " +
    "and nutrition. You can understand and answer in English, Marathi, Hindi, " +
    "or any language the user speaks. Always provide clear, accurate, " +
    "well-formatted markdown answers with emojis where appropriate. " +
    `Current category mode: ${category}.`;

  const requestBody = {
    system_instruction: {
      parts: [{ text: systemInstruction }],
    },
    contents: [
      {
        parts: [{ text: prompt }],
      },
    ],
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 1024,
    },
  };

  // Try each model in order.
  for (const model of MODELS) {
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/` +
      `${model}:generateContent?key=${GEMINI_API_KEY}`;

    try {
      const upstream = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(requestBody),
        signal: AbortSignal.timeout(15_000),
      });

      if (upstream.ok) {
        const data = await upstream.json();
        const candidates = data?.candidates as Array<{
          content?: { parts?: Array<{ text?: string }> };
        }> | undefined;

        const text = candidates?.[0]?.content?.parts?.[0]?.text?.trim();
        if (text) {
          return json({ text });
        }
      } else {
        console.error(`Gemini upstream error (${model}): ${upstream.status}`);
      }
    } catch (err) {
      console.error(`Gemini upstream request error (${model}): ${err}`);
    }
  }

  return json({ error: "Gemini upstream call failed for all models" }, 502);
});
