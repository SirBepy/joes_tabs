import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

/// Web connection.
///
/// We ship `sqlite3.wasm` + `drift_worker.js` in apps/app/web/ and try drift's
/// persistent web backend first. If those assets are missing or fail to load
/// (GRACEFUL FALLBACK), we open an in-memory database from the same wasm binary
/// so the app still runs - it just will not survive a full page reload.
///
/// Why a fallback at all: drift is pinned to the 2.31 line here (the analyzer-8
/// SDK ceiling blocks 2.32+), so a guaranteed version-matched worker pair is not
/// always available. Native (mobile/desktop) keeps full persistence regardless.
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      try {
        final result = await WasmDatabase.open(
          databaseName: 'joes_tabs_cache',
          sqlite3Uri: Uri.parse('sqlite3.wasm'),
          driftWorkerUri: Uri.parse('drift_worker.js'),
        );
        return result.resolvedExecutor;
      } catch (_) {
        // Persistent web storage unavailable: fall back to an in-memory
        // database (still backed by the wasm sqlite3) so the app runs without
        // crashing.
        final sqlite3 = await WasmSqlite3.loadFromUrl(
          Uri.parse('sqlite3.wasm'),
        );
        sqlite3.registerVirtualFileSystem(
          InMemoryFileSystem(),
          makeDefault: true,
        );
        return DatabaseConnection(WasmDatabase.inMemory(sqlite3));
      }
    }),
  );
}
