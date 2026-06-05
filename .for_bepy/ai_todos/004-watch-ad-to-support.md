# 004 - "Watch an ad to support us" integration

## Context
Joe wants a low-key monetization/support hook: a button somewhere in Settings (and it
already exists conceptually on the Support Us screen) that says something like "Watch
an ad to support us." Deliberately unobtrusive, opt-in, not nagging anyone.

## Priority
LOW - do this LAST, only after Phases A/B/C are done.

## What to do
- Add a rewarded-ad button in Settings (and/or wire the existing Support Us "Watch Ad"
  button) labeled "Watch an ad to support us".
- Use Google AdMob via the official `google_mobile_ads` package (run the mandatory
  package safety check first). Rewarded ad format.
- Use AdMob TEST ad unit ids for now (no real account needed to build/test). Real ad
  unit ids + the AdMob app id come from Joe later (needs his AdMob account).
- Mobile-only initially (AdMob does not support Flutter web). Guard with platform
  checks so web/desktop builds still compile and the button hides or shows a
  "mobile only" note on web.
- Graceful handling when no ad is available (button disabled / friendly message).

## Needs Joe (later)
- AdMob account -> app id + rewarded ad unit ids (production). Test ids are fine until
  then.

## Acceptance
- Settings shows the support button; on a mobile build it loads + shows a test rewarded
  ad; web build still compiles and degrades gracefully.
