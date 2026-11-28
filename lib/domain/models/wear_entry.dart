import 'dart:convert';

/// One day a look was worn ("Me lo puse hoy"). Row of the `wear_log` table.
class WearEntry {
  const WearEntry({
    this.id,
    required this.signature,
    required this.garmentIds,
    required this.wornOn,
  });

  final int? id;
  final String signature;
  final List<int> garmentIds;

  /// Local calendar day (time part is always midnight).
  final DateTime wornOn;

  /// `YYYY-MM-DD`, as stored in `wear_log.worn_on`.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => <String, Object?>{
        if (id != null) 'id': id,
        'signature': signature,
        'garment_ids': jsonEncode(garmentIds),
        'worn_on': dayKey(wornOn),
      };

  factory WearEntry.fromMap(Map<String, Object?> map) => WearEntry(
        id: map['id'] as int?,
        signature: map['signature'] as String,
        garmentIds: (jsonDecode(map['garment_ids'] as String) as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toList(),
        wornOn: DateTime.parse(map['worn_on'] as String),
      );
}
