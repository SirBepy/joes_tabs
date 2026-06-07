import 'package:drift/drift.dart';

import '../drift/app_database.dart';

/// Framework-free, typed snapshot of the single [AppSettings] row.
///
/// The on-disk `instruments` text is a comma-joined list of instrument slugs;
/// here it is decoded into [instrumentSlugs] (empty entries trimmed away). The
/// app layer maps these slugs to its own typed instrument enum - this layer
/// intentionally has no Flutter / material dependency.
class AppSettingsRecord {
  const AppSettingsRecord({
    required this.onboardingComplete,
    required this.themeMode,
    required this.instrumentSlugs,
    required this.fontSize,
    required this.maximalChords,
  });

  final bool onboardingComplete;
  final String themeMode;
  final List<String> instrumentSlugs;
  final int fontSize;
  final bool maximalChords;
}

/// Repository over the single-row [AppSettings] table.
///
/// Lazily seeds the row on first access, so callers always get a record even on
/// installs where the migration safety nets have not yet run. Encoding and
/// decoding of the comma-joined `instruments` slugs lives here.
class AppSettingsRepository {
  AppSettingsRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$AppSettingsTable, AppSetting> get _rowQuery =>
      _db.select(_db.appSettings)..where((t) => t.id.equals(kAppSettingsRowId));

  /// Reads the settings row, lazily creating the default row if it is missing.
  Future<AppSettingsRecord> read() async {
    var row = await _rowQuery.getSingleOrNull();
    if (row == null) {
      await _ensureRow();
      row = await _rowQuery.getSingle();
    }
    return _toRecord(row);
  }

  /// Reactive single-row watch. Seeds the row first so the stream always has a
  /// value to emit.
  Stream<AppSettingsRecord> watch() async* {
    await _ensureRow();
    yield* _rowQuery.watchSingle().map(_toRecord);
  }

  /// Partial update of any subset of fields. Provided [instrumentSlugs] are
  /// re-encoded to comma-joined text; omitted fields are left unchanged.
  Future<void> update({
    bool? onboardingComplete,
    String? themeMode,
    List<String>? instrumentSlugs,
    int? fontSize,
    bool? maximalChords,
  }) async {
    await _ensureRow();
    final companion = AppSettingsCompanion(
      onboardingComplete: onboardingComplete == null
          ? const Value.absent()
          : Value(onboardingComplete),
      themeMode: themeMode == null ? const Value.absent() : Value(themeMode),
      instruments: instrumentSlugs == null
          ? const Value.absent()
          : Value(_encode(instrumentSlugs)),
      fontSize: fontSize == null ? const Value.absent() : Value(fontSize),
      maximalChords: maximalChords == null
          ? const Value.absent()
          : Value(maximalChords),
    );
    await (_db.update(
      _db.appSettings,
    )..where((t) => t.id.equals(kAppSettingsRowId))).write(companion);
  }

  /// Inserts the default row (id [kAppSettingsRowId]) if absent. Idempotent.
  Future<void> _ensureRow() async {
    await _db
        .into(_db.appSettings)
        .insert(
          AppSettingsCompanion.insert(id: const Value(kAppSettingsRowId)),
          mode: InsertMode.insertOrIgnore,
        );
  }

  AppSettingsRecord _toRecord(AppSetting row) => AppSettingsRecord(
    onboardingComplete: row.onboardingComplete,
    themeMode: row.themeMode,
    instrumentSlugs: _decode(row.instruments),
    fontSize: row.fontSize,
    maximalChords: row.maximalChords,
  );

  /// Decodes comma-joined slug text into a trimmed, empty-free list.
  static List<String> _decode(String raw) =>
      raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// Encodes slugs to comma-joined text (trimmed, empties dropped).
  static String _encode(List<String> slugs) =>
      slugs.map((s) => s.trim()).where((s) => s.isNotEmpty).join(',');
}
