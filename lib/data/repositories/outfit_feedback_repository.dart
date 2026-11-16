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

  Future<Map<String, FeedbackRating>> latestRatingBySignature() async {
    final all = await getAll();
    final result = <String, FeedbackRating>{};
    for (final feedback in all) {
      result.putIfAbsent(feedback.signature, () => feedback.rating);
    }
    return result;
  }

  Future<int> count() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
