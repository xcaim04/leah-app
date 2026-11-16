import 'package:test/test.dart';
import 'package:mi_armario/domain/color/color_math.dart';
import 'package:mi_armario/domain/outfit/harmony_rules.dart';

void main() {
  group('classifyHarmony', () {
    test('neutral when any color is neutral', () {
      final white = rgbToHsl(255, 255, 255);
      final red = rgbToHsl(255, 0, 0);
      final r = classifyHarmony(white, red);
      expect(r.type, HarmonyType.neutral);
      expect(r.score, greaterThan(0.7));
    });

    test('monochrome for same hue', () {
      final a = rgbToHsl(255, 0, 0);
      final b = rgbToHsl(220, 20, 20);
      final r = classifyHarmony(a, b);
      expect(r.type, HarmonyType.monochrome);
    });

    test('analogous for close hues', () {
      final a = rgbToHsl(255, 0, 0); // 0
      final b = rgbToHsl(255, 128, 0); // ~30
      final r = classifyHarmony(a, b);
      expect(r.type, HarmonyType.analogous);
    });

    test('complementary for opposite hues', () {
      final a = rgbToHsl(255, 0, 0); // 0
      final b = rgbToHsl(0, 255, 255); // 180
      final r = classifyHarmony(a, b);
      expect(r.type, HarmonyType.complementary);
    });

    test('triad for ~120 degrees', () {
      final a = rgbToHsl(255, 0, 0); // 0
      final b = rgbToHsl(0, 255, 0); // 120
      final r = classifyHarmony(a, b);
      expect(r.type, HarmonyType.triad);
    });

    test('clash for close but different high-sat hues', () {
      final a = rgbToHsl(255, 0, 0); // 0
      final b = rgbToHsl(255, 80, 0); // ~19
      final r = classifyHarmony(a, b);
      expect(r.type, HarmonyType.clash);
      expect(r.score, lessThan(0.5));
    });
  });
}
