import 'package:sqflite/sqflite.dart';

import '../../domain/models/outfit_feedback.dart';
import '../db/app_database.dart';

class OutfitFeedbackRepository {
  OutfitFeedbackRepository(this._database);

  static const String table = 'outfit_feedback';

  final AppDatabase _database;

  Future<int> insert(OutfitFeedback feedback) async {
    final db = await _database.database;
    return db.insert(table, feedback.toMap());
  }

  Future<List<OutfitFeedback>> getAll() async {
    final db = await _database.database;
    final rows = await db.query(table, orderBy: 'created_at DESC, id DESC');
    return rows.map(OutfitFeedback.fromMap).toList();
  }

  Future<List<OutfitFeedback>> getBySignature(String signature) async {
    final db = await _database.database;
    final rows = await db.query(
      table,
      where: 'signature = ?',
      whereArgs: [signature],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(OutfitFeedback.fromMap).toList();
  }

  Future<void> deleteBySignature(String signature) async {
    final db = await _database.database;
    await db.delete(table, where: 'signature = ?', whereArgs: [signature]);
  }

  /// Swaps any previous votes for this look with [feedback] atomically.
  Future<void> replace(OutfitFeedback feedback) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(
        table,
        where: 'signature = ?',
        whereArgs: [feedback.signature],
      );
      await txn.insert(table, feedback.toMap());
    });
  }

  Future<int> count() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
