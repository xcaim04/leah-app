import '../../domain/models/wear_entry.dart';
import '../db/app_database.dart';

class WearLogRepository {
  WearLogRepository(this._database);

  static const String table = 'wear_log';

  final AppDatabase _database;

  /// Logs [entry], replacing the same look already logged that day.
  Future<void> add(WearEntry entry) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(
        table,
        where: 'signature = ? AND worn_on = ?',
        whereArgs: [entry.signature, WearEntry.dayKey(entry.wornOn)],
      );
      await txn.insert(table, entry.toMap()..remove('id'));
    });
  }

  /// Newest day first.
  Future<List<WearEntry>> getAll() async {
    final db = await _database.database;
    final rows = await db.query(table, orderBy: 'worn_on DESC, id DESC');
    return rows.map(WearEntry.fromMap).toList();
  }

  Future<void> deleteById(int id) async {
    final db = await _database.database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
