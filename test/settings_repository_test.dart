import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/data/db/app_database.dart';
import 'package:mi_armario/data/db/migrations.dart';
import 'package:mi_armario/data/repositories/garment_repository.dart';
import 'package:mi_armario/data/repositories/settings_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'garment_repository_test.dart' show buildGarment;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('SettingsRepository', () {
    late AppDatabase database;
    late SettingsRepository repository;

    setUp(() {
      database = AppDatabase(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      repository = SettingsRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('get returns null for a missing key', () async {
      expect(await repository.get('theme_mode'), isNull);
    });

    test('set stores and overwrites a value', () async {
      await repository.set('theme_mode', 'dark');
      expect(await repository.get('theme_mode'), 'dark');

      await repository.set('theme_mode', 'light');
      expect(await repository.get('theme_mode'), 'light');
    });
  });

  test('upgrading a v1 database adds settings and keeps garments', () async {
    final dir = await Directory.systemTemp.createTemp('mi_armario_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'upgrade.db');

    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => Migrations.createV1(db),
      ),
    );
    await v1.insert('garments', buildGarment(notes: 'antigua').toMap());
    await v1.close();

    final upgraded = AppDatabase(factory: databaseFactoryFfi, path: path);
    addTearDown(upgraded.close);
    final garments = GarmentRepository(upgraded);
    final settings = SettingsRepository(upgraded);

    final db = await upgraded.database;
    expect(await db.getVersion(), Migrations.version);

    final all = await garments.getAll();
    expect(all, hasLength(1));
    expect(all.single.notes, 'antigua');

    await settings.set('theme_mode', 'dark');
    expect(await settings.get('theme_mode'), 'dark');
  });
}
