import 'package:drift/drift.dart';

// Picks the native (file-backed) or web (in-memory fallback) opener at compile
// time. On non-web platforms we get a persistent sqlite file; on web we get an
// in-memory database so the app still runs without the drift wasm worker.
import 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart'
    as impl;

/// Opens the platform-appropriate [QueryExecutor] for [AppDatabase].
QueryExecutor openConnection() => impl.openConnection();
