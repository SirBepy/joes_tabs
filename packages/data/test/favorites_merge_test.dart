import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('favorites merge (first-sign-in sync)', () {
    test('mergeFavorites is the union of local and account', () {
      expect(mergeFavorites({'a', 'b'}, {'b', 'c'}), {'a', 'b', 'c'});
    });

    test('mergeFavorites with empty sides is identity', () {
      expect(mergeFavorites(<String>{}, {'x'}), {'x'});
      expect(mergeFavorites({'x'}, <String>{}), {'x'});
      expect(mergeFavorites(<String>{}, <String>{}), isEmpty);
    });

    test('toPush is local minus account (rows to upsert on the server)', () {
      expect(toPush({'a', 'b', 'c'}, {'b'}), {'a', 'c'});
      // Nothing to push when the account already has everything local.
      expect(toPush({'a'}, {'a', 'z'}), isEmpty);
    });

    test('toPull is account minus local (rows to add to Drift)', () {
      expect(toPull({'b'}, {'a', 'b', 'c'}), {'a', 'c'});
      expect(toPull({'a', 'z'}, {'a'}), isEmpty);
    });

    test('merge is idempotent: a converged state pushes/pulls nothing', () {
      const both = {'a', 'b', 'c'};
      expect(toPush(both, both), isEmpty);
      expect(toPull(both, both), isEmpty);
      expect(mergeFavorites(both, both), both);
    });
  });
}
