import 'package:sqflite/sqflite.dart' show DatabaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web: SQLite compiled to wasm, persisted in IndexedDB (needs web/sqlite3.wasm
/// and web/sqflite_sw.js from `dart run sqflite_common_ffi_web:setup`).
DatabaseFactory? platformDatabaseFactory() => databaseFactoryFfiWeb;
