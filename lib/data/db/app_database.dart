import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

/// Thin wrapper around sqflite that opens (and caches) the app database.
///
/// The [factory] and [path] parameters exist so tests can run against an
/// in-memory database via `sqflite_common_ffi`.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
      : _factory = factory,
        _path = path;

  static const String dbName = 'mi_armario.db';

  final DatabaseFactory? _factory;
  final String? _path;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final factory = _factory ?? databaseFactory;
    final path = _path ?? p.join(await getDatabasesPath(), dbName);
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: Migrations.version,
        onCreate: Migrations.onCreate,
        onUpgrade: Migrations.onUpgrade,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
