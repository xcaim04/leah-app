import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../domain/models/garment_color.dart';

class PaletteExtractor {
  Future<List<GarmentColor>> extract(Uint8List imageBytes) async {
    final generator = await PaletteGenerator.fromImageProvider(
      MemoryImage(imageBytes),
      maximumColorCount: 16,
    );

    final entries = generator.paletteColors.toList();
    if (entries.isEmpty) {
      return const <GarmentColor>[];
    }

    final totalPopulation = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.population,
    );

    final colors = entries.map((entry) {
      final value = entry.color.toARGB32();
      final weight = totalPopulation > 0
          ? entry.population / totalPopulation
          : 1 / entries.length;
      return GarmentColor(
        red: (value >> 16) & 0xFF,
        green: (value >> 8) & 0xFF,
        blue: value & 0xFF,
        weight: weight.toDouble(),
      );
    }).toList();

    colors.sort((a, b) => b.weight.compareTo(a.weight));
    return colors.take(5).toList();
  }
}
