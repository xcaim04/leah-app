import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/garment_repository.dart';
import '../../data/repositories/outfit_feedback_repository.dart';
import '../../data/services/image_storage.dart';
import '../../data/services/palette_extractor.dart';
import '../../domain/models/garment.dart';
import '../../domain/models/outfit_feedback.dart';

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

final imageStorageProvider = Provider<ImageStorage>((ref) => ImageStorage());

final paletteExtractorProvider =
    Provider<PaletteExtractor>((ref) => PaletteExtractor());

final outfitFeedbackRepositoryProvider = Provider<OutfitFeedbackRepository>(
  (ref) => OutfitFeedbackRepository(ref.watch(appDatabaseProvider)),
);

final outfitFeedbackProvider = FutureProvider<List<OutfitFeedback>>(
  (ref) => ref.watch(outfitFeedbackRepositoryProvider).getAll(),
);
