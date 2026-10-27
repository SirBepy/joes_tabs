// Pure query/response shaping for the web-search function, free of Deno APIs
// so `node --test` can exercise it (see search.test.ts).

// Mirrors WebTabSite.all in packages/models: a site added there must be added
// here too, or its pages never come back from search.
export const SITE_HOSTS = [
  "ukulele-tabs.com",
  "chordie.com",
  "e-chords.com",
  "ultimate-guitar.com",
] as const;

export const MAX_QUERY_LENGTH = 200;

export type WebResult = { title: string; url: string; description: string };

/** Normalised user query, or null when there is nothing worth searching. */
export function cleanQuery(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const q = raw.replace(/\s+/g, " ").trim();
  if (q.length === 0 || q.length > MAX_QUERY_LENGTH) return null;
  return q;
}

/** The Brave query: the user's words plus "chords", limited to SITE_HOSTS. */
export function buildBraveQuery(query: string): string {
  const sites = SITE_HOSTS.map((h) => `site:${h}`).join(" OR ");
  return `${query} chords ${sites}`;
}

export function isAllowedUrl(raw: string): boolean {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return false;
  }
  if (url.protocol !== "https:" && url.protocol !== "http:") return false;
  const host = url.hostname.toLowerCase();
  return SITE_HOSTS.some((h) => host === h || host.endsWith(`.${h}`));
}

const ENTITIES: Record<string, string> = {
  "&amp;": "&",
  "&lt;": "<",
  "&gt;": ">",
  "&quot;": '"',
  "&#39;": "'",
  "&#x27;": "'",
  "&nbsp;": " ",
};

/** Brave wraps matched words in <strong> and escapes entities; undo both. */
export function stripMarkup(text: string): string {
  return text
    .replace(/<[^>]*>/g, "")
    .replace(/&(?:amp|lt|gt|quot|#39|#x27|nbsp);/g, (e) => ENTITIES[e] ?? e)
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Brave's response reduced to allowlisted pages, deduplicated by URL. Brave's
 * `site:` operators are documented as best effort, so the host check here is
 * what actually enforces the allowlist.
 */
export function mapBraveResults(body: unknown): WebResult[] {
  const results = (body as { web?: { results?: unknown[] } })?.web?.results;
  if (!Array.isArray(results)) return [];
  const seen = new Set<string>();
  const out: WebResult[] = [];
  for (const r of results) {
    const item = r as { title?: unknown; url?: unknown; description?: unknown };
    if (typeof item.url !== "string" || !isAllowedUrl(item.url)) continue;
    if (seen.has(item.url)) continue;
    seen.add(item.url);
    out.push({
      title: stripMarkup(typeof item.title === "string" ? item.title : ""),
      url: item.url,
      description: stripMarkup(
        typeof item.description === "string" ? item.description : "",
      ),
    });
  }
  return out;
}
