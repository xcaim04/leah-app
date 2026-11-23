import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/data/services/image_storage.dart';

void main() {
  group('ImageStorageHelper', () {
    test('stored extension is always jpg (output is jpeg)', () {
      expect(ImageStorageHelper.fileExtension, '.jpg');
    });

    test('buildFileNames creates unique names with preserved extension', () {
      final now = DateTime(2026, 1, 2, 3, 4, 5, 6);
      final names = ImageStorageHelper.buildFileNames(
        now: now,
        randomValue: 42,
      );
      final base = '${now.microsecondsSinceEpoch}_42';
      expect(names.photoName, '$base.jpg');
      expect(names.thumbName, '${base}_thumb.jpg');
    });

    test('relative paths use photos and thumbs folders', () {
      expect(ImageStorageHelper.photoRelativePath('a.jpg'), 'photos/a.jpg');
      expect(ImageStorageHelper.thumbRelativePath('a.jpg'), 'thumbs/a.jpg');
    });
  });
}
