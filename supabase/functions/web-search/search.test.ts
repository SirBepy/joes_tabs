// Run: node --test supabase/functions/web-search/search.test.ts
// (Node 22.18+ strips the TypeScript types natively.)
import { test } from "node:test";
import assert from "node:assert/strict";
import {
  buildBraveQuery,
  cleanQuery,
  isAllowedUrl,
  mapBraveResults,
  MAX_QUERY_LENGTH,
  stripMarkup,
} from "./search.ts";

test("cleanQuery trims, collapses whitespace and rejects junk", () => {
  assert.equal(cleanQuery("  steven   universe "), "steven universe");
  assert.equal(cleanQuery(""), null);
  assert.equal(cleanQuery("   "), null);
  assert.equal(cleanQuery(42), null);
  assert.equal(cleanQuery("x".repeat(MAX_QUERY_LENGTH + 1)), null);
});

test("buildBraveQuery limits the search to the allowlisted sites", () => {
  assert.equal(
    buildBraveQuery("love like you"),
    "love like you chords site:ukulele-tabs.com OR site:chordie.com OR " +
      "site:e-chords.com OR site:ultimate-guitar.com",
  );
});

test("isAllowedUrl accepts allowlisted hosts and subdomains only", () => {
  assert.ok(isAllowedUrl("https://ukulele-tabs.com/a.html"));
  assert.ok(isAllowedUrl("https://tabs.ultimate-guitar.com/tab/x"));
  assert.ok(!isAllowedUrl("https://chordie.com.evil.io/x"));
  assert.ok(!isAllowedUrl("https://notchordie.com/x"));
  assert.ok(!isAllowedUrl("javascript:alert(1)"));
  assert.ok(!isAllowedUrl("not a url"));
});

test("stripMarkup removes Brave's highlight tags and entities", () => {
  assert.equal(
    stripMarkup("<strong>Love</strong> Like You &amp; Me &#39;n&#x27;"),
    "Love Like You & Me 'n'",
  );
});

test("mapBraveResults keeps allowlisted, unique results only", () => {
  const body = {
    web: {
      results: [
        {
          title: "<strong>Love Like You</strong> Ukulele Tabs",
          url: "https://ukulele-tabs.com/love.html",
          description: "Chords &amp; lyrics",
        },
        { title: "dup", url: "https://ukulele-tabs.com/love.html" },
        { title: "Elsewhere", url: "https://songsterr.com/x" },
        { title: "No url" },
        { title: "UG", url: "https://tabs.ultimate-guitar.com/tab/su" },
      ],
    },
  };
  assert.deepEqual(mapBraveResults(body), [
    {
      title: "Love Like You Ukulele Tabs",
      url: "https://ukulele-tabs.com/love.html",
      description: "Chords & lyrics",
    },
    {
      title: "UG",
      url: "https://tabs.ultimate-guitar.com/tab/su",
      description: "",
    },
  ]);
});

test("mapBraveResults tolerates an unexpected body", () => {
  assert.deepEqual(mapBraveResults(null), []);
  assert.deepEqual(mapBraveResults({}), []);
  assert.deepEqual(mapBraveResults({ web: { results: "nope" } }), []);
});
