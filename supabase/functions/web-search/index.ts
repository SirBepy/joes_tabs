// web-search: finds chord pages on the allowlisted sites through the Brave
// Search API. Signed-in users only, so the metered Brave key can't be drained
// by anonymous traffic. Brave's terms forbid storing or caching results, so
// nothing here persists them.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { buildBraveQuery, cleanQuery, mapBraveResults } from "./search.ts";

const BRAVE_ENDPOINT = "https://api.search.brave.com/res/v1/web/search";

// Best-effort per-user throttle. It lives in this isolate's memory, so it
// resets on cold starts; it exists to stop a runaway client loop, not abuse.
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 20;
const recent = new Map<string, number[]>();

function throttled(userId: string): boolean {
  const now = Date.now();
  const hits = (recent.get(userId) ?? []).filter((t) => now - t < WINDOW_MS);
  if (hits.length >= MAX_PER_WINDOW) {
    recent.set(userId, hits);
    return true;
  }
  hits.push(now);
  recent.set(userId, hits);
  return false;
}

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json(405, { error: "method not allowed" });

  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return json(401, { error: "sign in to search the web" });
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
  );
  const { data: userData, error: authError } = await supabase.auth.getUser(
    token,
  );
  if (authError || !userData?.user) {
    return json(401, { error: "sign in to search the web" });
  }

  let payload: { query?: unknown };
  try {
    payload = await req.json();
  } catch {
    return json(400, { error: "body must be JSON" });
  }
  const query = cleanQuery(payload.query);
  if (!query) return json(400, { error: "invalid query" });

  if (throttled(userData.user.id)) {
    return json(429, { error: "too many searches, try again in a minute" });
  }

  const key = Deno.env.get("BRAVE_API_KEY");
  if (!key) return json(503, { error: "web search is not configured" });

  const url = new URL(BRAVE_ENDPOINT);
  url.searchParams.set("q", buildBraveQuery(query));
  url.searchParams.set("count", "20");
  const res = await fetch(url, {
    headers: { Accept: "application/json", "X-Subscription-Token": key },
  });
  if (!res.ok) {
    console.error("brave search failed", res.status, await res.text());
    return json(502, { error: "web search failed" });
  }

  return json(200, { results: mapBraveResults(await res.json()) });
});
