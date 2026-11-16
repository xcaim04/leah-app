import 'dart:convert';

/// A single dominant colour of a garment, stored as 8-bit RGB channels plus
/// the proportion ([weight]) reported by the palette extractor.
class GarmentColor {
  const GarmentColor({
    required this.red,
    required this.green,
    required this.blue,
    this.weight = 0,
  });

  final int red;
  final int green;
  final int blue;

  /// Fraction of the garment image covered by this colour (0..1).
  final double weight;

  Map<String, Object?> toJson() => {
        'r': red,
        'g': green,
        'b': blue,
        'w': weight,
      };

  factory GarmentColor.fromJson(Map<String, Object?> json) => GarmentColor(
        red: (json['r'] as num).toInt(),
        green: (json['g'] as num).toInt(),
        blue: (json['b'] as num).toInt(),
        weight: (json['w'] as num?)?.toDouble() ?? 0,
      );

  String toHex() {
    final r = red.toRadixString(16).padLeft(2, '0');
    final g = green.toRadixString(16).padLeft(2, '0');
    final b = blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  factory GarmentColor.fromHex(String hex) {
    final value = hex.replaceFirst('#', '');
    return GarmentColor(
      red: int.parse(value.substring(0, 2), radix: 16),
      green: int.parse(value.substring(2, 4), radix: 16),
      blue: int.parse(value.substring(4, 6), radix: 16),
    );
  }

  static String encodeList(List<GarmentColor> colors) =>
      jsonEncode(colors.map((c) => c.toJson()).toList());

  static List<GarmentColor> decodeList(String raw) {
    if (raw.isEmpty) return const <GarmentColor>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => GarmentColor.fromJson(e as Map<String, Object?>))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      other is GarmentColor &&
      other.red == red &&
      other.green == green &&
      other.blue == blue &&
      other.weight == weight;

  @override
  int get hashCode => Object.hash(red, green, blue, weight);
}
