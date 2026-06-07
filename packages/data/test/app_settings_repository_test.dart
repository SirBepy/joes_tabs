import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AppSettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AppSettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('default row exists after DB creation with seeded defaults', () async {
    final record = await repo.read();
    expect(record.onboardingComplete, isFalse);
    expect(record.themeMode, 'system');
    expect(record.instrumentSlugs, ['ukulele', 'guitar']);
    expect(record.fontSize, 20);
  });

  test('update round-trips each field', () async {
    await repo.update(
      onboardingComplete: true,
      themeMode: 'dark',
      instrumentSlugs: ['guitar'],
      fontSize: 28,
    );

    final record = await repo.read();
    expect(record.onboardingComplete, isTrue);
    expect(record.themeMode, 'dark');
    expect(record.instrumentSlugs, ['guitar']);
    expect(record.fontSize, 28);
  });

  test('partial update leaves omitted fields unchanged', () async {
    await repo.update(themeMode: 'light');
    final record = await repo.read();
    expect(record.themeMode, 'light');
    // Untouched fields keep their defaults.
    expect(record.onboardingComplete, isFalse);
    expect(record.instrumentSlugs, ['ukulele', 'guitar']);
    expect(record.fontSize, 20);
  });

  test('instrumentSlugs encode/decode trims empties', () async {
    await repo.update(instrumentSlugs: ['ukulele', '', ' guitar ']);
    final record = await repo.read();
    expect(record.instrumentSlugs, ['ukulele', 'guitar']);
  });

  test('watch emits the updated value after an update', () async {
    // Prime the row, then assert the stream reflects a subsequent write.
    await repo.read();
    final emitted = expectLater(
      repo.watch().map((r) => r.themeMode),
      emitsThrough('dark'),
    );
    await repo.update(themeMode: 'dark');
    await emitted;
  });

  test('maximalChords round-trips and defaults false', () async {
    expect((await repo.read()).maximalChords, isFalse);
    await repo.update(maximalChords: true);
    expect((await repo.read()).maximalChords, isTrue);
  });

  // Migration is covered by the onCreate / onUpgrade / beforeOpen idempotency in
  // AppDatabase (insert-if-absent of the single row, create-if-not-exists of the
  // table). The repo has no drift schema-dump migration-test infrastructure, so
  // a formal SchemaVerifier test is intentionally not scaffolded here.
}
