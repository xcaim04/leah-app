import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/domain/color/color_math.dart';

void main() {
  group('rgbToHsl', () {
    test('pure red is hue 0, full saturation', () {
      final hsl = rgbToHsl(255, 0, 0);
      expect(hsl.hue, closeTo(0, 0.001));
      expect(hsl.saturation, closeTo(1, 0.001));
      expect(hsl.lightness, closeTo(0.5, 0.001));
    });

    test('pure green is hue 120', () {
      expect(rgbToHsl(0, 255, 0).hue, closeTo(120, 0.001));
    });

    test('pure blue is hue 240', () {
      expect(rgbToHsl(0, 0, 255).hue, closeTo(240, 0.001));
    });

    test('white has zero saturation and full lightness', () {
      final hsl = rgbToHsl(255, 255, 255);
      expect(hsl.saturation, closeTo(0, 0.001));
      expect(hsl.lightness, closeTo(1, 0.001));
    });

    test('black has zero saturation and zero lightness', () {
      final hsl = rgbToHsl(0, 0, 0);
      expect(hsl.saturation, closeTo(0, 0.001));
      expect(hsl.lightness, closeTo(0, 0.001));
    });
  });

  group('hueDistance', () {
    test('wraps around 360', () {
      expect(hueDistance(10, 350), closeTo(20, 0.001));
    });

    test('is symmetric', () {
      expect(hueDistance(40, 200), closeTo(hueDistance(200, 40), 0.001));
    });

    test('opposite hues are 180 apart', () {
      expect(hueDistance(0, 180), closeTo(180, 0.001));
    });
  });

  group('isNeutral', () {
    test('white, black and grey are neutral', () {
      expect(isNeutral(rgbToHsl(255, 255, 255)), isTrue);
      expect(isNeutral(rgbToHsl(0, 0, 0)), isTrue);
      expect(isNeutral(rgbToHsl(128, 128, 128)), isTrue);
    });

    test('saturated red is not neutral', () {
      expect(isNeutral(rgbToHsl(255, 0, 0)), isFalse);
    });
  });
}
