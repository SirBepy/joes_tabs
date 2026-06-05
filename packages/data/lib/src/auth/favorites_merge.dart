/// Pure favorites-merge helpers used by the first-sign-in account sync.
///
/// The sync is intentionally simple and idempotent (spec section 5: "local
/// favorites are pushed to the user's account on first sign-in; nothing lost").
/// On sign-in we:
///   1. compute the union of local + account favorite ids ([mergeFavorites]),
///   2. push the ids that are missing on the server ([toPush]),
///   3. pull the ids that are missing locally ([toPull]) into Drift.
/// All three are pure set operations over song-id strings, so they are unit
/// tested without any database or network.

/// The merged set of favorites after sign-in: every id present locally OR on
/// the account. Order is not significant (favorites are a set; the Saved screen
/// re-sorts by its own `created_at`).
Set<String> mergeFavorites(Set<String> local, Set<String> account) {
  return {...local, ...account};
}

/// Local ids that the account does not yet have, i.e. the rows to insert into
/// `user_favorites` on sign-in. `local - account`.
Set<String> toPush(Set<String> local, Set<String> account) {
  return local.difference(account);
}

/// Account ids missing from the local Drift store, i.e. the favorites to add
/// locally so the Saved screen reflects the account. `account - local`.
Set<String> toPull(Set<String> local, Set<String> account) {
  return account.difference(local);
}
