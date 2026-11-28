import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../presentation/providers/providers.dart';
import '../db/app_database.dart';
import '../db/migrations.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider)),
);

class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Full-database JSON export/import. Tables are discovered generically.
class BackupService {
  BackupService(this._database);

  static const _app = 'mi_armario';
  static const _format = 1;

  final AppDatabase _database;

  Future<List<String>> _tables(DatabaseExecutor db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );
    return [for (final r in rows) r['name'] as String];
  }

  Future<Uint8List> export() async {
    final db = await _database.database;
    final tables = <String, Object?>{};
    for (final t in await _tables(db)) {
      final rows = await db.query('"$t"');
      tables[t] = [
        for (final row in rows)
          {
            for (final e in row.entries)
              e.key: e.value is Uint8List
                  ? {r'$b64': base64Encode(e.value as Uint8List)}
                  : e.value,
          },
      ];
    }
    return utf8.encode(
      jsonEncode({
        'app': _app,
        'format': _format,
        'schemaVersion': Migrations.version,
        'exportedAt': DateTime.now().toIso8601String(),
        'tables': tables,
      }),
    );
  }

  Future<void> import(Uint8List bytes) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      throw BackupException('El archivo no es una copia válida.');
    }
    if (data['app'] != _app ||
        data['format'] != _format ||
        data['tables'] is! Map) {
      throw BackupException('El archivo no es una copia de Mi armario.');
    }
    final version = data['schemaVersion'];
    if (version is! int || version > Migrations.version) {
      throw BackupException(
        'La copia es de una versión más reciente de la app. Actualiza la app e inténtalo de nuevo.',
      );
    }
    final backup = data['tables'] as Map<String, dynamic>;

    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.execute('PRAGMA defer_foreign_keys = ON');
      for (final t in await _tables(txn)) {
        await txn.delete('"$t"');
        final rows = backup[t];
        if (rows is! List) continue;
        final cols = {
          for (final c in await txn.rawQuery('PRAGMA table_info("$t")'))
            c['name'] as String,
        };
        for (final row in rows) {
          final values = <String, Object?>{};
          for (final e in (row as Map<String, dynamic>).entries) {
            if (!cols.contains(e.key)) continue;
            final v = e.value;
            values[e.key] = v is Map && v[r'$b64'] is String
                ? base64Decode(v[r'$b64'] as String)
                : v;
          }
          if (values.isNotEmpty) await txn.insert('"$t"', values);
        }
      }
    });
  }
}
