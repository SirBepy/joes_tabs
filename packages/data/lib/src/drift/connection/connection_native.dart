import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Native (mobile/desktop) connection: a file-backed sqlite database in the
/// app's documents directory, opened lazily so no platform channel runs until
/// the first query. The bundled native sqlite3 comes from sqlite3_flutter_libs.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'joes_tabs_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
