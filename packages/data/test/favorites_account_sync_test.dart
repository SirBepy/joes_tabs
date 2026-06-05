import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake account repo: an in-memory id set standing in for `user_favorites`.
/// Records pushes so the test can assert local-only ids were sent up.
class FakeAccountFavoritesRepository implements AccountFavoritesRepository {
  FakeAccountFavoritesRepository(this._remote);

  final Set<String> _remote;
  final List<String> pushed = [];

  @override
  Future<Set<String>> fetchFavoriteIds() async => {..._remote};

  @override
  Future<void> pushFavoriteIds(Iterable<String> songIds) async {
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
}
