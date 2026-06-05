import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/state/favorites_provider.dart';

/// In-memory account sink standing in for `user_favorites`, with a flippable
/// signed-in flag and an optional failure injection.
class FakeAccountFavoritesSink implements AccountFavoritesSink {
  bool signedIn = true;
  bool throwOnWrite = false;

  final List<String> added = [];
  final List<String> removed = [];

  @override
  Future<void> add(String songId) async {
    if (!signedIn) return;
    if (throwOnWrite) throw StateError('account write failed');
    added.add(songId);
  }

  @override
  Future<void> remove(String songId) async {
    if (!signedIn) return;
    if (throwOnWrite) throw StateError('account write failed');
    removed.add(songId);
  }
}

/// Pumps the event loop so the notifier's fire-and-forget account mirror and
/// the Drift stream listener have run.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('toggling while signed in writes to BOTH local and account', () async {
    final sink = FakeAccountFavoritesSink()..signedIn = true;
    final notifier = DriftFavoritesNotifier(db, accountSink: sink);
    addTearDown(notifier.dispose);

    notifier.add('song-1');
    await _settle();

    // Local Drift updated.
    expect((await db.favoriteIds()).toSet(), {'song-1'});
    // Account mirrored.
    expect(sink.added, ['song-1']);

    notifier.remove('song-1');
    await _settle();

    expect((await db.favoriteIds()), isEmpty);
    expect(sink.removed, ['song-1']);
  });

  test('toggling while signed out writes ONLY local', () async {
    final sink = FakeAccountFavoritesSink()..signedIn = false;
    final notifier = DriftFavoritesNotifier(db, accountSink: sink);
    addTearDown(notifier.dispose);

    notifier.add('song-1');
    await _settle();

    expect((await db.favoriteIds()).toSet(), {'song-1'});
    expect(sink.added, isEmpty);
    expect(sink.removed, isEmpty);
  });

  test(
    'an account-write failure still updates local and does not throw',
    () async {
      final sink = FakeAccountFavoritesSink()
        ..signedIn = true
        ..throwOnWrite = true;
      final notifier = DriftFavoritesNotifier(db, accountSink: sink);
      addTearDown(notifier.dispose);

      // Must not throw despite the account write failing.
      expect(() => notifier.add('song-1'), returnsNormally);
      await _settle();

      // Local stays the source of truth.
      expect((await db.favoriteIds()).toSet(), {'song-1'});
    },
  );

  test(
    'no sink (anonymous / no backend) toggles local only, no throw',
    () async {
      final notifier = DriftFavoritesNotifier(db);
      addTearDown(notifier.dispose);

      notifier.add('song-1');
      await _settle();

      expect((await db.favoriteIds()).toSet(), {'song-1'});
    },
  );

  test('on sign-in the account set is pulled into local', () async {
    // Local has only "a"; the account has "b" + "c".
    await db.addFavorite('a');
    final account = _FakeFetchRepo({'b', 'c'});

    await FavoritesAccountSync(db, account).run();

    // The Saved screen (local Drift) now reflects the account union.
    expect((await db.favoriteIds()).toSet(), {'a', 'b', 'c'});
    // Local-only "a" was pushed up to the account.
    expect(account.pushed, ['a']);
  });
}

/// Minimal repo for the sign-in pull test.
class _FakeFetchRepo implements AccountFavoritesRepository {
  _FakeFetchRepo(this._remote);
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

  @override
  Future<void> removeFavoriteId(String songId) async => _remote.remove(songId);
}
