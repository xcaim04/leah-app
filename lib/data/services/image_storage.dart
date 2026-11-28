import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../db/app_database.dart';

class ImageStorageException implements Exception {
  ImageStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'ImageStorageException: $message';
}

class ImageStorageHelper {
  static const int thumbWidth = 300;

  /// JPEG thumbnail [thumbWidth] px wide (never upscaled), or null if [bytes]
  /// isn't a decodable image. Pure Dart so it runs on web and in `compute`.
  static Uint8List? buildThumbnail(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final resized = decoded.width > thumbWidth
        ? img.copyResize(decoded, width: thumbWidth)
        : decoded;
    return img.encodeJpg(resized, quality: 75);
  }
}

/// Stores photos as BLOBs in the `images` table; ids are returned as text so
/// they fit the existing `garments.photo_path` / `thumb_path` columns.
class ImageStorage {
  ImageStorage(this._database);

  static const String _table = 'images';

  final AppDatabase _database;

  /// [picked] is already downscaled by the picker (maxWidth/imageQuality).
  Future<({String photoId, String thumbId})> save(XFile picked) async {
    try {
      final photoBytes = await picked.readAsBytes();
      final thumbBytes = await compute(
        ImageStorageHelper.buildThumbnail,
        photoBytes,
      );
      if (thumbBytes == null) {
        throw ImageStorageException('No se pudo procesar la imagen');
      }
      final db = await _database.database;
      return await db.transaction((txn) async {
        final photoId = await txn.insert(_table, {'bytes': photoBytes});
        final thumbId = await txn.insert(_table, {'bytes': thumbBytes});
        return (photoId: '$photoId', thumbId: '$thumbId');
      });
    } on ImageStorageException {
      rethrow;
    } catch (e) {
      throw ImageStorageException('No se pudo guardar la imagen', e);
    }
  }

  Future<Uint8List?> load(String id) async {
    final key = int.tryParse(id);
    if (key == null) return null; // pre-v3 file path: photo not migrated
    final db = await _database.database;
    final rows = await db.query(
      _table,
      columns: ['bytes'],
      where: 'id = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['bytes'] as Uint8List;
  }

  Future<void> delete(String photoId, String thumbId) async {
    try {
      final db = await _database.database;
      await db.delete(
        _table,
        where: 'id IN (?, ?)',
        whereArgs: [int.tryParse(photoId), int.tryParse(thumbId)],
      );
    } catch (e) {
      throw ImageStorageException('No se pudo eliminar la imagen', e);
    }
  }
}
