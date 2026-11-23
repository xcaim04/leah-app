import 'garment_color.dart';

/// Broad kind of a garment. Identifier in English, label in Spanish.
enum GarmentCategory { top, bottom, dress, footwear, outerwear, accessory }

extension GarmentCategoryX on GarmentCategory {
  String get label => switch (this) {
        GarmentCategory.top => 'Parte superior',
        GarmentCategory.bottom => 'Parte inferior',
        GarmentCategory.dress => 'Vestido',
        GarmentCategory.footwear => 'Calzado',
        GarmentCategory.outerwear => 'Abrigo',
        GarmentCategory.accessory => 'Accesorio',
      };
}

/// Context in which a garment is meant to be worn.
enum Occasion { casual, work, party, sport }

extension OccasionX on Occasion {
  String get label => switch (this) {
        Occasion.casual => 'Casual',
        Occasion.work => 'Trabajo',
        Occasion.party => 'Fiesta',
        Occasion.sport => 'Deporte',
      };
}

/// Weather season a garment suits.
enum Season { summer, winter, midSeason, all }

extension SeasonX on Season {
  String get label => switch (this) {
        Season.summer => 'Verano',
        Season.winter => 'Invierno',
        Season.midSeason => 'Entretiempo',
        Season.all => 'Todo el año',
      };

  /// Two seasons are compatible when they match or one of them is [all].
  bool isCompatibleWith(Season other) =>
      this == other || this == Season.all || other == Season.all;
}

/// A single item in the wardrobe.
class Garment {
  const Garment({
    this.id,
    required this.photoPath,
    required this.thumbPath,
    required this.category,
    required this.colors,
    required this.occasion,
    required this.season,
    this.notes,
    this.favorite = false,
    required this.createdAt,
  });

  final int? id;
  final String photoPath;
  final String thumbPath;
  final GarmentCategory category;
  final List<GarmentColor> colors;
  final Occasion occasion;
  final Season season;
  final String? notes;
  final bool favorite;
  final DateTime createdAt;

  Garment copyWith({
    int? id,
    String? photoPath,
    String? thumbPath,
    GarmentCategory? category,
    List<GarmentColor>? colors,
    Occasion? occasion,
    Season? season,
    String? notes,
    bool? favorite,
    DateTime? createdAt,
  }) {
    return Garment(
      id: id ?? this.id,
      photoPath: photoPath ?? this.photoPath,
      thumbPath: thumbPath ?? this.thumbPath,
      category: category ?? this.category,
      colors: colors ?? this.colors,
      occasion: occasion ?? this.occasion,
      season: season ?? this.season,
      notes: notes ?? this.notes,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        if (id != null) 'id': id,
        'photo_path': photoPath,
        'thumb_path': thumbPath,
        'category': category.name,
        'colors': GarmentColor.encodeList(colors),
        'occasion': occasion.name,
        'season': season.name,
        'notes': notes,
        'favorite': favorite ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Garment.fromMap(Map<String, Object?> map) => Garment(
        id: map['id'] as int?,
        photoPath: map['photo_path'] as String,
        thumbPath: map['thumb_path'] as String,
        category: GarmentCategory.values.byName(map['category'] as String),
        colors: GarmentColor.decodeList(map['colors'] as String),
        occasion: Occasion.values.byName(map['occasion'] as String),
        season: Season.values.byName(map['season'] as String),
        notes: map['notes'] as String?,
        favorite: (map['favorite'] as int? ?? 0) == 1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
