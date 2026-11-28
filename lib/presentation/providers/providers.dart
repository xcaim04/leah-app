import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/garment_repository.dart';
import '../../data/repositories/outfit_feedback_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/wear_log_repository.dart';
import '../../data/services/image_storage.dart';
import '../../data/services/palette_extractor.dart';
import '../../domain/models/garment.dart';
import '../../domain/models/outfit_feedback.dart';
import '../../domain/models/wear_entry.dart';

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

final imageStorageProvider = Provider<ImageStorage>(
  (ref) => ImageStorage(ref.watch(appDatabaseProvider)),
);

/// Image bytes by id (see `garments.photo_path`). Ids are never reused, so
/// entries only need invalidating to free memory after a delete.
final imageBytesProvider = FutureProvider.family<Uint8List?, String>(
  (ref, id) => ref.watch(imageStorageProvider).load(id),
);

final paletteExtractorProvider = Provider<PaletteExtractor>(
  (ref) => PaletteExtractor(),
);

final outfitFeedbackRepositoryProvider = Provider<OutfitFeedbackRepository>(
  (ref) => OutfitFeedbackRepository(ref.watch(appDatabaseProvider)),
);

final outfitFeedbackProvider = FutureProvider<List<OutfitFeedback>>(
  (ref) => ref.watch(outfitFeedbackRepositoryProvider).getAll(),
);

final wearLogRepositoryProvider = Provider<WearLogRepository>(
  (ref) => WearLogRepository(ref.watch(appDatabaseProvider)),
);

/// Every "Me lo puse hoy" entry, newest first.
final wearLogProvider = FutureProvider<List<WearEntry>>(
  (ref) => ref.watch(wearLogRepositoryProvider).getAll(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// App theme mode (Sistema / Claro / Oscuro), persisted in `settings`.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String settingsKey = 'theme_mode';

  bool _userChanged = false;

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final stored = await ref
          .read(settingsRepositoryProvider)
          .get(settingsKey);
      final mode = ThemeMode.values.asNameMap()[stored];
      // Don't clobber a choice made while the DB was still opening.
      if (mode != null && !_userChanged) state = mode;
    } catch (_) {
      // Unreadable setting: keep following the system theme.
    }
  }

  Future<void> set(ThemeMode mode) async {
    _userChanged = true;
    state = mode;
    await ref.read(settingsRepositoryProvider).set(settingsKey, mode.name);
  }
}
