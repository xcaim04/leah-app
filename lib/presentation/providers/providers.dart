import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/garment_repository.dart';
import '../../domain/models/garment.dart';

/// Owns the single database instance for the whole app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final garmentRepositoryProvider = Provider<GarmentRepository>(
  (ref) => GarmentRepository(ref.watch(appDatabaseProvider)),
);

/// All garments, newest first. Invalidate to refresh after mutations.
final garmentsProvider = FutureProvider<List<Garment>>(
  (ref) => ref.watch(garmentRepositoryProvider).getAll(),
);
