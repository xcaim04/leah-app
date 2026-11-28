import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/data/backup/backup_service.dart';
import 'package:mi_armario/data/db/app_database.dart';
import 'package:mi_armario/data/db/migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

AppDatabase _newDb() => AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );

Future<Map<String, List<Map<String, Object?>>>> _dump(AppDatabase d) async {
  final db = await d.database;
  final out = <String, List<Map<String, Object?>>>{};
  for (final t in ['garments', 'images', 'settings', 'outfit_feedback']) {
    out[t] = await db.query(t, orderBy: 'rowid');
  }
  return out;
}

void main() {
  setUpAll(sqfliteFfiInit);

  test('round trip restores all tables including blobs', () async {
    final a = _newDb();
    final db = await a.database;
    await db.insert('images', {
      'id': 7,
      'bytes': Uint8List.fromList([0, 1, 2, 255]),
    });
    await db.insert('settings', {'key': 'k', 'value': 'v'});
    // Fill required garment/feedback columns generically from the schema.
    for (final t in ['garments', 'outfit_feedback']) {
      final cols = await db.rawQuery('PRAGMA table_info($t)');
      final row = <String, Object?>{};
      for (final c in cols) {
        if (c['pk'] == 1 && c['type'] == 'INTEGER') continue;
        if (c['notnull'] == 1 && c['dflt_value'] == null) {
          row[c['name'] as String] = c['type'] == 'TEXT' ? 'x' : 1;
        }
      }
      await db.insert(t, row);
    }
    final before = await _dump(a);
    final bytes = await BackupService(a).export();

    final b = _newDb();
    await (await b.database).insert('settings', {'key': 'old', 'value': '1'});
    await BackupService(b).import(bytes);
    expect(await _dump(b), before);
    expect(before['garments'], isNotEmpty);
    expect(before['outfit_feedback'], isNotEmpty);
    await a.close();
    await b.close();
  });

  test('rejects invalid file', () async {
    final a = _newDb();
    expect(
      () => BackupService(a).import(Uint8List.fromList(utf8.encode('nope'))),
      throwsA(isA<BackupException>()),
    );
    expect(
      () => BackupService(a)
          .import(Uint8List.fromList(utf8.encode('{"app":"other"}'))),
      throwsA(isA<BackupException>()),
    );
    await a.close();
  });

  test('rejects newer schema', () async {
    final a = _newDb();
    final bytes = utf8.encode(jsonEncode({
      'app': 'mi_armario',
      'format': 1,
      'schemaVersion': Migrations.version + 1,
      'tables': {},
    }));
    expect(
      () => BackupService(a).import(Uint8List.fromList(bytes)),
      throwsA(isA<BackupException>()),
    );
    await a.close();
  });
}
