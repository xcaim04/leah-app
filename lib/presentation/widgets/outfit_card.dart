import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../../domain/models/outfit.dart';
import '../../domain/models/outfit_feedback.dart';
import '../providers/outfit_providers.dart';

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
              Row(
                children: [
                  for (final (i, g) in outfit.garments.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _GarmentImage(garment: g)),
                  ],
                ],
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                  constraints: const BoxConstraints(minWidth: 48),
                  itemBuilder: (context) => [
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
          child: Image.file(
            File(garment.thumbPath),
            fit: BoxFit.cover,
            cacheWidth: 400,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.checkroom_outlined, color: scheme.onSurfaceVariant),
          ),
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
