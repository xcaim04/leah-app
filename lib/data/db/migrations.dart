import 'package:sqflite/sqflite.dart';

/// Schema definition and version upgrades for the local database.
class Migrations {
  Migrations._();

  static const int version = 1;

  static Future<void> onCreate(Database db, int version) async {
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
    // Reserved for future schema migrations.
  }
}
