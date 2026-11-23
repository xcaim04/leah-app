import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/data/db/app_database.dart';
import 'package:mi_armario/data/repositories/outfit_feedback_repository.dart';
import 'package:mi_armario/domain/models/outfit_feedback.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

OutfitFeedback buildFeedback({
  String signature = '1-2',
  List<int> garmentIds = const [1, 2],
  FeedbackRating rating = FeedbackRating.like,
  DateTime? createdAt,
}) {
  return OutfitFeedback(
    signature: signature,
    garmentIds: garmentIds,
    rating: rating,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late AppDatabase database;
  late OutfitFeedbackRepository repository;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = OutfitFeedbackRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('insert and getAll return feedback newest first', () async {
    await repository.insert(buildFeedback(
      signature: '1-2',
      createdAt: DateTime(2026, 1, 1),
    ));
    await repository.insert(buildFeedback(
      signature: '2-3',
      garmentIds: const [2, 3],
      rating: FeedbackRating.dislike,
      createdAt: DateTime(2026, 1, 2),
    ));

    final all = await repository.getAll();
    expect(all, hasLength(2));
    expect(all.first.signature, '2-3');
    expect(all.first.rating, FeedbackRating.dislike);
    expect(await repository.count(), 2);
  });

  test('getBySignature filters by signature', () async {
    await repository.insert(buildFeedback(signature: '1-2'));
    await repository.insert(buildFeedback(signature: '3-4', garmentIds: const [3, 4]));

    final rows = await repository.getBySignature('1-2');
    expect(rows, hasLength(1));
    expect(rows.single.signature, '1-2');
  });

  test('deleteBySignature removes all entries for a signature', () async {
    await repository.insert(buildFeedback(signature: '1-2'));
    await repository.insert(buildFeedback(signature: '1-2'));
    await repository.insert(buildFeedback(signature: '3-4', garmentIds: const [3, 4]));

    await repository.deleteBySignature('1-2');
    expect(await repository.getBySignature('1-2'), isEmpty);
    expect(await repository.count(), 1);
  });

  test('replace swaps previous votes for the signature', () async {
    await repository.insert(buildFeedback(signature: '1-2'));
    await repository.insert(buildFeedback(signature: '3-4', garmentIds: const [3, 4]));

    await repository.replace(buildFeedback(
      signature: '1-2',
      rating: FeedbackRating.dislike,
    ));

    final rows = await repository.getBySignature('1-2');
    expect(rows, hasLength(1));
    expect(rows.single.rating, FeedbackRating.dislike);
    expect(await repository.count(), 2);
  });
}
