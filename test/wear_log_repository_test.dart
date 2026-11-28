import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/data/db/app_database.dart';
import 'package:mi_armario/data/repositories/wear_log_repository.dart';
import 'package:mi_armario/domain/models/wear_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

WearEntry entry(String signature, DateTime day) => WearEntry(
  signature: signature,
  garmentIds: signature.split('-').map(int.parse).toList(),
  wornOn: day,
);

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase database;
  late WearLogRepository repository;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = WearLogRepository(database);
  });

  tearDown(() => database.close());

  test('getAll returns newest day first', () async {
    await repository.add(entry('1-2', DateTime(2026, 3, 1)));
    await repository.add(entry('3-4', DateTime(2026, 3, 5)));
    final all = await repository.getAll();
    expect(all.map((e) => e.signature), ['3-4', '1-2']);
    expect(all.first.garmentIds, [3, 4]);
    expect(all.first.wornOn, DateTime(2026, 3, 5));
  });

  test('same look on the same day is stored once', () async {
    await repository.add(entry('1-2', DateTime(2026, 3, 1)));
    await repository.add(entry('1-2', DateTime(2026, 3, 1)));
    await repository.add(entry('1-2', DateTime(2026, 3, 2)));
    await repository.add(entry('3-4', DateTime(2026, 3, 1)));
    expect(await repository.getAll(), hasLength(3));
  });

  test('deleteById removes only that entry', () async {
    await repository.add(entry('1-2', DateTime(2026, 3, 1)));
    await repository.add(entry('3-4', DateTime(2026, 3, 1)));
    final first = (await repository.getAll()).first;
    await repository.deleteById(first.id!);
    final rest = await repository.getAll();
    expect(rest, hasLength(1));
    expect(rest.single.id, isNot(first.id));
  });
}
