import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../../domain/models/outfit.dart';
import '../../domain/models/outfit_feedback.dart';
import '../providers/outfit_providers.dart';
import '../share/share_look.dart';
import 'garment_image.dart';

class OutfitCard extends ConsumerWidget {
  const OutfitCard({
    super.key,
    required this.outfit,
    this.showFeedback = true,
    this.showScore = false,
  });

  final Outfit outfit;
  final bool showFeedback;
  final bool showScore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final liked =
        ref.watch(latestRatingsProvider)[outfit.signature] ==
        FeedbackRating.like;
    final controller = ref.read(feedbackControllerProvider);
    final wornToday = ref.watch(wornTodayProvider)[outfit.signature];
    final wearLog = ref.read(wearLogControllerProvider);

    void snack(String message) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Cap each 3:4 image at 260 high by capping the row's width.
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        outfit.garments.length * 260 * 3 / 4 +
                        (outfit.garments.length - 1) * 8,
                  ),
                  child: Row(
                    children: [
                      for (final (i, g) in outfit.garments.indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: _GarmentImage(garment: g)),
                      ],
                    ],
                  ),
                ),
              ),
              if (showScore)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _ScoreBadge(scorePct: (outfit.score * 100).round()),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            outfit.explanation,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (showFeedback)
            Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  icon: Icon(
                    wornToday != null ? Icons.event_available : Icons.checkroom,
                  ),
                  label: Text(
                    wornToday != null ? 'Puesto hoy' : 'Me lo puse hoy',
                  ),
                  onPressed: wornToday != null
                      ? () {
                          wearLog.delete(wornToday.id!);
                          snack('Quitado del diario de hoy');
                        }
                      : () {
                          wearLog.wearToday(outfit);
                          snack('Guardado en tu diario');
                        },
                ),
                const Spacer(),
                IconButton(
                  tooltip: liked
                      ? 'Quitar de favoritos'
                      : 'Guardar en favoritos',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  onPressed: liked
                      ? () => controller.clear(outfit)
                      : () => controller.like(outfit),
                ),
                PopupMenuButton<void>(
                  tooltip: 'Más opciones',
                  icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                  // Card context, not the menu's: the menu is gone when onTap runs.
                  itemBuilder: (_) => [
                    PopupMenuItem<void>(
                      onTap: () => shareOutfit(context, ref, outfit),
                      child: const ListTile(
                        leading: Icon(Icons.share),
                        title: Text('Compartir'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem<void>(
                      onTap: () {
                        controller.dislike(outfit);
                        snack('No volveremos a sugerir este look');
                      },
                      child: const ListTile(
                        leading: Icon(Icons.block),
                        title: Text('No sugerir más'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Responsive grid of [OutfitCard]s: 1 column on phones, up to 3 on wide
/// windows, content capped at 1280. Place inside a [CustomScrollView].
class SliverOutfitGrid extends StatelessWidget {
  const SliverOutfitGrid({super.key, required this.outfits});

  final List<Outfit> outfits;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, c) {
      final contentW = (c.crossAxisExtent.clamp(0, 1280) - 32).toDouble();
      final side = (c.crossAxisExtent - contentW) / 2;
      final cols = (contentW / 400).floor().clamp(1, 3);
      final rows = (outfits.length / cols).ceil();
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(side, 8, side, 16),
        sliver: SliverList.separated(
          itemCount: rows,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, r) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) const SizedBox(width: 14),
                Expanded(
                  child: r * cols + j < outfits.length
                      ? OutfitCard(outfit: outfits[r * cols + j])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _GarmentImage extends StatelessWidget {
  const _GarmentImage({required this.garment});

  final Garment garment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: garment.category.label,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: GarmentImage(imageId: garment.thumbPath, cacheWidth: 400),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.scorePct});

  final int scorePct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Compatibilidad: $scorePct por ciento',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '$scorePct%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
