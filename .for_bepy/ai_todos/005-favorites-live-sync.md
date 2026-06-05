# 005 - Continuous favorites live sync (signed-in accounts)

## Context
v1 auth ships a pragmatic, sign-in-time favorites merge between the local Drift
store and the per-user `user_favorites` Supabase table (spec section 5). On
every transition into a signed-in state (`currentUserProvider` change in
`main.dart`), `FavoritesAccountSync.run()`:
- pushes local-only ids up to `user_favorites` (idempotent upsert), and
- pulls account-only ids down into Drift.

This converges both stores once, but it is NOT continuous: while signed in,
favoriting/unfavoriting a song writes ONLY to the local Drift store. It is not
mirrored to `user_favorites` live, and changes made on another device are not
pulled until the next sign-in.

## What is deferred
Continuous two-way sync while signed in:
- On `DriftFavoritesNotifier.add/remove`, when a user is signed in, also
  upsert/delete the row in `user_favorites`.
- On sign-out, stop mirroring (anonymous keeps local-only behaviour, unchanged).
- Optionally subscribe to Supabase realtime on `user_favorites` to reflect
  remote changes live.
- Handle un-favorite: the current sync only adds/pushes (union), it never
  deletes. A live design needs a tombstone / delete strategy so removing a
  favorite on one device removes it everywhere.

## Where to wire it
- `apps/app/lib/state/favorites_provider.dart` (`DriftFavoritesNotifier`) is the
  natural mirror point; it would need the `AccountFavoritesRepository` +
  current user id injected.
- `packages/data/lib/src/auth/account_favorites_repository.dart` already has
  `pushFavoriteIds`; add a `removeFavoriteId` + maybe a realtime stream.

## Acceptance
- Favoriting while signed in immediately writes to `user_favorites`.
- Un-favoriting while signed in removes the server row.
- A second device reflects changes (realtime or on next focus).
- Anonymous (logged-out) favorites remain local-only and unchanged.
