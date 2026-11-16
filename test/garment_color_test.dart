import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/domain/models/garment_color.dart';

void main() {
  group('GarmentColor json codec', () {
    test('round-trips a list of colours', () {
      const colors = [
        GarmentColor(red: 10, green: 20, blue: 30, weight: 0.5),
        GarmentColor(red: 200, green: 100, blue: 50, weight: 0.25),
      ];
      final encoded = GarmentColor.encodeList(colors);
      final decoded = GarmentColor.decodeList(encoded);

      expect(decoded.length, 2);
      expect(decoded[0], colors[0]);
      expect(decoded[1], colors[1]);
    });

    test('empty string decodes to empty list', () {
      expect(GarmentColor.decodeList(''), isEmpty);
    });
  });

  group('hex conversion', () {
    test('converts to padded uppercase hex', () {
      const color = GarmentColor(red: 5, green: 160, blue: 255);
      expect(color.toHex(), '#05A0FF');
    });

    test('parses hex back to channels', () {
      final color = GarmentColor.fromHex('#05A0FF');
      expect(color.red, 5);
      expect(color.green, 160);
      expect(color.blue, 255);
    });
  });
}
