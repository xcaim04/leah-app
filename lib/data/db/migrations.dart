import 'package:sqflite/sqflite.dart';

/// Schema definition and version upgrades for the local database.
class Migrations {
  Migrations._();

  static const int version = 2;

  static Future<void> onCreate(Database db, int version) async {
    await createV1(db);
    await _createV2(db);
  }

  /// Original v1 schema (wardrobe + feedback). Public so tests can build a
  /// v1 database and exercise the upgrade path.
  static Future<void> createV1(Database db) async {
    await db.execute('''
      CREATE TABLE garments (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        photo_path  TEXT NOT NULL,
        thumb_path  TEXT NOT NULL,
        category    TEXT NOT NULL,
        colors      TEXT NOT NULL,
        occasion    TEXT NOT NULL,
        season      TEXT NOT NULL,
        notes       TEXT,
        favorite    INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_garments_category ON garments(category)',
    );

    await db.execute('''
      CREATE TABLE outfit_feedback (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        signature   TEXT NOT NULL,
        garment_ids TEXT NOT NULL,
        rating      INTEGER NOT NULL,
        created_at  INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_feedback_signature ON outfit_feedback(signature)',
    );
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _createV2(db);
  }

  /// v2: key/value app settings. Purely additive, never touches wardrobe data.
  static Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
