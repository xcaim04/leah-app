import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';

/// Key/value app preferences stored in the `settings` table.
class SettingsRepository {
  SettingsRepository(this._database);

  static const String table = 'settings';

  final AppDatabase _database;

  Future<String?> get(String key) async {
    final db = await _database.database;
    final rows = await db.query(
      table,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> set(String key, String value) async {
    final db = await _database.database;
    await db.insert(
      table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
