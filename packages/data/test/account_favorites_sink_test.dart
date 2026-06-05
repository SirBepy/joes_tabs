import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repo recording the single-id add/remove write-through calls.
class FakeAccountFavoritesRepository implements AccountFavoritesRepository {
  final List<String> pushed = [];
  final List<String> removed = [];

  @override
  Future<Set<String>> fetchFavoriteIds() async =>
      {...pushed}..removeAll(removed);

  @override
  Future<void> pushFavoriteIds(Iterable<String> songIds) async {
    pushed.addAll(songIds);
  }

  @override
  Future<void> removeFavoriteId(String songId) async {
    removed.add(songId);
  }
}

void main() {
  group('LiveAccountFavoritesSink', () {
    test('writes through to the account when signed in', () async {
      final repo = FakeAccountFavoritesRepository();
      final sink = LiveAccountFavoritesSink(
        repository: repo,
        isSignedIn: () => true,
      );

      await sink.add('a');
      await sink.remove('b');

      expect(repo.pushed, ['a']);
      expect(repo.removed, ['b']);
    });

    test('no-ops while signed out (anonymous stays local-only)', () async {
      final repo = FakeAccountFavoritesRepository();
      final sink = LiveAccountFavoritesSink(
        repository: repo,
        isSignedIn: () => false,
      );

      await sink.add('a');
      await sink.remove('b');

      expect(repo.pushed, isEmpty);
      expect(repo.removed, isEmpty);
    });

    test(
      'reads the latest auth state on each write (no stale snapshot)',
      () async {
        final repo = FakeAccountFavoritesRepository();
        var signedIn = false;
        final sink = LiveAccountFavoritesSink(
          repository: repo,
          isSignedIn: () => signedIn,
        );

        await sink.add('before'); // signed out -> dropped
        signedIn = true;
        await sink.add('after'); // signed in -> written

        expect(repo.pushed, ['after']);
      },
    );
  });
}
