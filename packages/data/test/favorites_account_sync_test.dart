import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake account repo: an in-memory id set standing in for `user_favorites`.
/// Records pushes so the test can assert local-only ids were sent up.
class FakeAccountFavoritesRepository implements AccountFavoritesRepository {
  FakeAccountFavoritesRepository(this._remote);

  final Set<String> _remote;
  final List<String> pushed = [];

  /// When set, [fetchFavoriteIds] throws this instead of returning.
  Object? throwOnFetch;

  /// When set, [pushFavoriteIds] throws this instead of upserting.
  Object? throwOnPush;

  /// Number of times [pushFavoriteIds] was invoked at all (even with empties).
  int pushCalls = 0;

  @override
  Future<Set<String>> fetchFavoriteIds() async {
    if (throwOnFetch != null) throw throwOnFetch!;
    return {..._remote};
  }

  @override
  Future<void> pushFavoriteIds(Iterable<String> songIds) async {
    pushCalls++;
    if (throwOnPush != null) throw throwOnPush!;
    for (final id in songIds) {
      pushed.add(id);
      _remote.add(id);
    }
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'sign-in sync pushes local-only up and pulls account-only down',
    () async {
      // Local has a + b; account has b + c.
      await db.addFavorite('a');
      await db.addFavorite('b');
      final account = FakeAccountFavoritesRepository({'b', 'c'});

      final merged = await FavoritesAccountSync(db, account).run();

      // Union present in both stores.
      expect(merged, {'a', 'b', 'c'});
      expect((await db.favoriteIds()).toSet(), {'a', 'b', 'c'});
      // Only the local-only id was pushed (b already on the account).
      expect(account.pushed, ['a']);
    },
  );

  test('sync is idempotent: a second run pushes and pulls nothing', () async {
    await db.addFavorite('a');
    final account = FakeAccountFavoritesRepository({'a'});

    await FavoritesAccountSync(db, account).run();
    account.pushed.clear();

    final merged = await FavoritesAccountSync(db, account).run();
    expect(merged, {'a'});
    expect(account.pushed, isEmpty);
    expect((await db.favoriteIds()).toSet(), {'a'});
  });

  test('empty local + empty account converges to empty', () async {
    final account = FakeAccountFavoritesRepository(<String>{});
    final merged = await FavoritesAccountSync(db, account).run();
    expect(merged, isEmpty);
    expect(await db.favoriteIds(), isEmpty);
    expect(account.pushed, isEmpty);
  });

  test(
    'empty local + populated account is a pure pull (no push call)',
    () async {
      final account = FakeAccountFavoritesRepository({'x', 'y'});
      final merged = await FavoritesAccountSync(db, account).run();

      expect(merged, {'x', 'y'});
      expect((await db.favoriteIds()).toSet(), {'x', 'y'});
      // Nothing local-only, so pushFavoriteIds is never even invoked.
      expect(account.pushCalls, 0);
      expect(account.pushed, isEmpty);
    },
  );

  test(
    'populated local + empty account is a pure push (nothing to pull)',
    () async {
      await db.addFavorite('a');
      await db.addFavorite('b');
      final account = FakeAccountFavoritesRepository(<String>{});

      final merged = await FavoritesAccountSync(db, account).run();

      expect(merged, {'a', 'b'});
      // Both local ids pushed; local store unchanged (no account-only ids).
      expect(account.pushed.toSet(), {'a', 'b'});
      expect((await db.favoriteIds()).toSet(), {'a', 'b'});
    },
  );

  test(
    'a fetch failure propagates and leaves the local store untouched',
    () async {
      await db.addFavorite('a');
      final account = FakeAccountFavoritesRepository({'b'})
        ..throwOnFetch = StateError('offline');

      // Spec: a failed sync must surface to the caller (which logs + continues),
      // never silently swallow. It must also not have mutated local state.
      await expectLater(
        FavoritesAccountSync(db, account).run(),
        throwsA(isA<StateError>()),
      );
      expect((await db.favoriteIds()).toSet(), {'a'});
    },
  );

  test('a push failure propagates before any pull is applied', () async {
    // Local has only "a" (a push candidate); account has "c" (a pull candidate).
    // The push runs first and throws, so the pull must NOT have happened.
    await db.addFavorite('a');
    final account = FakeAccountFavoritesRepository({'c'})
      ..throwOnPush = StateError('write rejected');

    await expectLater(
      FavoritesAccountSync(db, account).run(),
      throwsA(isA<StateError>()),
    );
    // Pull side effect ("c") never applied because the push threw first.
    expect((await db.favoriteIds()).toSet(), {'a'});
  });
}
