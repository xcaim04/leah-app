import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/data/db/app_database.dart';
import 'package:mi_armario/data/repositories/garment_repository.dart';
import 'package:mi_armario/domain/models/garment.dart';
import 'package:mi_armario/domain/models/garment_color.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Garment buildGarment({
  GarmentCategory category = GarmentCategory.top,
  Occasion occasion = Occasion.casual,
  Season season = Season.all,
  bool favorite = false,
  String? notes,
}) {
  return Garment(
    photoPath: '/photos/a.jpg',
    thumbPath: '/thumbs/a.jpg',
    category: category,
    colors: const [GarmentColor(red: 1, green: 2, blue: 3, weight: 1)],
    occasion: occasion,
    season: season,
    favorite: favorite,
    notes: notes,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late AppDatabase database;
  late GarmentRepository repository;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = GarmentRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('insert assigns an id and getById returns the row', () async {
    final id = await repository.insert(buildGarment(notes: 'favorita'));
    final stored = await repository.getById(id);

    expect(stored, isNotNull);
    expect(stored!.id, id);
    expect(stored.category, GarmentCategory.top);
    expect(stored.notes, 'favorita');
    expect(stored.colors.single.toHex(), '#010203');
  });

  test('update persists changes', () async {
    final id = await repository.insert(buildGarment());
    final stored = (await repository.getById(id))!;

    await repository.update(
      stored.copyWith(category: GarmentCategory.dress, notes: 'cambiado'),
    );

    final updated = await repository.getById(id);
    expect(updated!.category, GarmentCategory.dress);
    expect(updated.notes, 'cambiado');
  });

  test('deleteById returns the removed garment', () async {
    final id = await repository.insert(buildGarment());
    final removed = await repository.deleteById(id);

    expect(removed, isNotNull);
    expect(removed!.id, id);
    expect(await repository.getById(id), isNull);
    expect(await repository.count(), 0);
  });

  test('filters by category, occasion and season', () async {
    await repository.insert(buildGarment(category: GarmentCategory.top));
    await repository.insert(buildGarment(category: GarmentCategory.dress));
    await repository.insert(
      buildGarment(category: GarmentCategory.top, occasion: Occasion.work),
    );

    expect((await repository.getAll()).length, 3);
    expect(
      (await repository.getAll(category: GarmentCategory.top)).length,
      2,
    );
    expect(
      (await repository.getAll(
        category: GarmentCategory.top,
        occasion: Occasion.work,
      ))
          .length,
      1,
    );
  });

  test('setFavorite toggles the flag', () async {
    final id = await repository.insert(buildGarment());
    await repository.setFavorite(id, true);
    expect((await repository.getById(id))!.favorite, isTrue);
  });
}
