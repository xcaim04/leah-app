import 'package:sqflite/sqflite.dart';

/// Schema definition and version upgrades for the local database.
class Migrations {
  Migrations._();

  static const int version = 4;

  static Future<void> onCreate(Database db, int version) async {
    await createV1(db);
    await _createV2(db);
    await _createV3(db);
    await _createV4(db);
  }

  /// Original v1 schema (wardrobe + feedback). Public so tests can build a
  /// v1 database and exercise the upgrade path.
  static Future<void> createV1(Database db) async {
    // Since v3 photo_path/thumb_path hold the `images.id` (as text), not a file path.
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
    if (oldVersion < 3) await _createV3(db);
    if (oldVersion < 4) await _createV4(db);
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

  /// v3: photo bytes live in the DB so the app also works on web. Old
  /// file-based photos are not migrated (no installs had data worth keeping).
  static Future<void> _createV3(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS images (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        bytes BLOB NOT NULL
      )
    ''');
  }

  /// v4: "Me lo puse hoy" diary, one row per look per day.
  static Future<void> _createV4(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wear_log (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        signature   TEXT NOT NULL,
        garment_ids TEXT NOT NULL,
        worn_on     TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_wear_log_worn_on ON wear_log(worn_on)',
    );
  }
}
