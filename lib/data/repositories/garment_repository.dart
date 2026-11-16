import 'package:sqflite/sqflite.dart';

import '../../domain/models/garment.dart';
import '../db/app_database.dart';

/// CRUD and filtered queries for [Garment] rows.
class GarmentRepository {
  GarmentRepository(this._database);

  static const String table = 'garments';

  final AppDatabase _database;

  Future<List<Garment>> getAll({
    GarmentCategory? category,
    Occasion? occasion,
    Season? season,
  }) async {
    final db = await _database.database;
    final where = <String>[];
    final args = <Object?>[];

    if (category != null) {
      where.add('category = ?');
      args.add(category.name);
    }
    if (occasion != null) {
      where.add('occasion = ?');
      args.add(occasion.name);
    }
    if (season != null) {
      where.add('season = ?');
      args.add(season.name);
    }

    final rows = await db.query(
      table,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
    );
    return rows.map(Garment.fromMap).toList();
  }

  Future<Garment?> getById(int id) async {
    final db = await _database.database;
    final rows = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Garment.fromMap(rows.first);
  }

  Future<int> insert(Garment garment) async {
    final db = await _database.database;
    return db.insert(table, garment.toMap());
  }

  Future<void> update(Garment garment) async {
    assert(garment.id != null, 'Cannot update a garment without an id');
    final db = await _database.database;
    await db.update(
      table,
      garment.toMap(),
      where: 'id = ?',
      whereArgs: [garment.id],
    );
  }

  /// Deletes the row and returns the removed garment so the caller can delete
  /// the associated files from disk.
  Future<Garment?> deleteById(int id) async {
    final garment = await getById(id);
    if (garment == null) return null;
    final db = await _database.database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
    return garment;
  }

  Future<void> setFavorite(int id, bool favorite) async {
    final db = await _database.database;
    await db.update(
      table,
      {'favorite': favorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> count() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
