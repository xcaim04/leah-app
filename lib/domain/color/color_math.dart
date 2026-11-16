/// Pure Dart colour helpers used by the outfit engine.
///
/// No Flutter imports here: this file must stay unit-testable on its own.
library;

class HslColor {
  const HslColor(this.hue, this.saturation, this.lightness);

  /// Hue in degrees, 0..360.
  final double hue;

  /// Saturation 0..1.
  final double saturation;

  /// Lightness 0..1.
  final double lightness;
}

/// Converts 8-bit RGB channels to [HslColor].
HslColor rgbToHsl(int red, int green, int blue) {
  final r = red / 255.0;
  final g = green / 255.0;
  final b = blue / 255.0;

  final max = [r, g, b].reduce((a, b) => a > b ? a : b);
  final min = [r, g, b].reduce((a, b) => a < b ? a : b);
  final delta = max - min;

  double hue;
  if (delta == 0) {
    hue = 0;
  } else if (max == r) {
    hue = 60 * (((g - b) / delta) % 6);
  } else if (max == g) {
    hue = 60 * (((b - r) / delta) + 2);
  } else {
    hue = 60 * (((r - g) / delta) + 4);
  }
  if (hue < 0) hue += 360;

  final lightness = (max + min) / 2;
  final saturation =
      delta == 0 ? 0.0 : delta / (1 - (2 * lightness - 1).abs());

  return HslColor(hue, saturation, lightness);
}

/// Shortest angular distance between two hues, 0..180 degrees.
double hueDistance(double a, double b) {
  final diff = (a - b).abs() % 360;
  return diff > 180 ? 360 - diff : diff;
}

/// Neutral colours combine with everything (white, black, greys, beige, navy).
bool isNeutral(HslColor color) =>
    color.saturation < 0.15 || color.lightness < 0.12 || color.lightness > 0.92;
