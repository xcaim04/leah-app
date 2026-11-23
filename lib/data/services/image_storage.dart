import 'dart:io';
import 'dart:math';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageException implements Exception {
  ImageStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'ImageStorageException: $message';
}

class ImageFileNames {
  const ImageFileNames({required this.photoName, required this.thumbName});

  final String photoName;
  final String thumbName;
}

class ImageStorageHelper {
  static final Random _random = Random();

  /// Compressed output is always JPEG, so the stored extension is always .jpg.
  static const fileExtension = '.jpg';

  static String generateBaseName({DateTime? now, int? randomValue}) {
    final time = now ?? DateTime.now();
    final random = randomValue ?? _random.nextInt(1 << 20);
    return '${time.microsecondsSinceEpoch}_$random';
  }

  static ImageFileNames buildFileNames({DateTime? now, int? randomValue}) {
    const ext = fileExtension;
    final base = generateBaseName(now: now, randomValue: randomValue);
    return ImageFileNames(photoName: '$base$ext', thumbName: '${base}_thumb$ext');
  }

  static String photoRelativePath(String fileName) => p.join('photos', fileName);

  static String thumbRelativePath(String fileName) => p.join('thumbs', fileName);
}

class ImageStorage {
  ImageStorage({Future<Directory> Function()? documentsDirectoryProvider})
      : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<({String photoPath, String thumbPath})> save(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        throw ImageStorageException('El archivo de origen no existe');
      }
      final baseDir = await _documentsDirectoryProvider();
      final photosDir = Directory(p.join(baseDir.path, 'photos'));
      final thumbsDir = Directory(p.join(baseDir.path, 'thumbs'));
      await photosDir.create(recursive: true);
      await thumbsDir.create(recursive: true);

      final names = ImageStorageHelper.buildFileNames();
      final photoTarget = p.join(photosDir.path, names.photoName);
      final thumbTarget = p.join(thumbsDir.path, names.thumbName);

      final photoBytes = await FlutterImageCompress.compressWithFile(
        sourcePath,
        minWidth: 1080,
        minHeight: 1080,
        quality: 80,
      );
      final thumbBytes = await FlutterImageCompress.compressWithFile(
        sourcePath,
        minWidth: 300,
        minHeight: 300,
        quality: 70,
      );

      if (photoBytes == null || thumbBytes == null) {
        throw ImageStorageException('No se pudo procesar la imagen');
      }

      await File(photoTarget).writeAsBytes(photoBytes, flush: true);
      await File(thumbTarget).writeAsBytes(thumbBytes, flush: true);

      return (photoPath: photoTarget, thumbPath: thumbTarget);
    } on ImageStorageException {
      rethrow;
    } catch (e) {
      throw ImageStorageException('No se pudo guardar la imagen', e);
    }
  }

  Future<void> delete(String photoPath, String thumbPath) async {
    try {
      final photo = File(photoPath);
      if (await photo.exists()) {
        await photo.delete();
      }
      final thumb = File(thumbPath);
      if (await thumb.exists()) {
        await thumb.delete();
      }
    } catch (e) {
      throw ImageStorageException('No se pudo eliminar la imagen', e);
    }
  }
}
