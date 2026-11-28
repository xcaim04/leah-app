import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mi_armario/data/db/app_database.dart';
import 'package:mi_armario/data/db/migrations.dart';
import 'package:mi_armario/data/services/image_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Uint8List _png(int width, int height) =>
    img.encodePng(img.Image(width: width, height: height));

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('ImageStorageHelper.buildThumbnail', () {
    test('scales wide images down to 300px, keeping aspect ratio', () {
      final thumb = img.decodeJpg(
        ImageStorageHelper.buildThumbnail(_png(600, 400))!,
      )!;
      expect(thumb.width, 300);
      expect(thumb.height, 200);
    });

    test('never upscales small images', () {
      final thumb = img.decodeJpg(
        ImageStorageHelper.buildThumbnail(_png(100, 50))!,
      )!;
      expect(thumb.width, 100);
    });

    test('returns null for non-image bytes', () {
      expect(
        ImageStorageHelper.buildThumbnail(Uint8List.fromList([1, 2, 3])),
        isNull,
      );
    });
  });

  group('ImageStorage', () {
    late AppDatabase database;
    late ImageStorage storage;

    setUp(() {
      database = AppDatabase(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      storage = ImageStorage(database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'save stores photo and thumbnail, load returns them, delete removes them',
      () async {
        final photo = _png(600, 400);
        final saved = await storage.save(XFile.fromData(photo));

        expect(await storage.load(saved.photoId), photo);
        final thumb = img.decodeJpg((await storage.load(saved.thumbId))!)!;
        expect(thumb.width, 300);

        await storage.delete(saved.photoId, saved.thumbId);
        expect(await storage.load(saved.photoId), isNull);
        expect(await storage.load(saved.thumbId), isNull);
      },
    );

    test('save rejects non-image bytes', () async {
      expect(
        storage.save(XFile.fromData(Uint8List.fromList([1, 2, 3]))),
        throwsA(isA<ImageStorageException>()),
      );
    });

    test('load returns null for legacy file paths and unknown ids', () async {
      expect(await storage.load('/data/photos/a.jpg'), isNull);
      expect(await storage.load('999'), isNull);
    });
  });

  test('upgrading a v2 database adds the images table', () async {
    final dir = await Directory.systemTemp.createTemp('mi_armario_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'upgrade.db');

    final v2 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await Migrations.createV1(db);
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
        },
      ),
    );
    await v2.close();

    final upgraded = AppDatabase(factory: databaseFactoryFfi, path: path);
    addTearDown(upgraded.close);
    expect(await (await upgraded.database).getVersion(), Migrations.version);

    final storage = ImageStorage(upgraded);
    final saved = await storage.save(XFile.fromData(_png(40, 40)));
    expect(await storage.load(saved.photoId), isNotNull);
  });
}
