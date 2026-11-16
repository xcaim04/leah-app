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
  });

  final Outfit outfit;
  final bool showFeedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scorePct = (outfit.score * 100).round();
    final ratings = ref.watch(latestRatingsProvider);
    final rating = ratings[outfit.signature];
    final controller = ref.read(feedbackControllerProvider);

    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in outfit.garments) _GarmentThumb(garment: g),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ScoreBadge(scorePct: scorePct),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            outfit.explanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (showFeedback) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _FeedbackButton(
                  tooltip: 'Me gusta',
                  icon: rating == FeedbackRating.like
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  active: rating == FeedbackRating.like,
                  activeColor: scheme.primary,
                  onPressed: () => controller.like(outfit),
                ),
                const SizedBox(width: 4),
                _FeedbackButton(
                  tooltip: 'No me gusta',
                  icon: rating == FeedbackRating.dislike
                      ? Icons.thumb_down
                      : Icons.thumb_down_outlined,
                  active: rating == FeedbackRating.dislike,
                  activeColor: scheme.error,
                  onPressed: () => controller.dislike(outfit),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GarmentThumb extends StatelessWidget {
  const _GarmentThumb({required this.garment});

  final Garment garment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: garment.category.label,
      child: Container(
        width: 58,
        height: 72,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(garment.thumbPath),
          fit: BoxFit.cover,
          cacheWidth: 240,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.checkroom_outlined,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active
          ? activeColor.withValues(alpha: 0.12)
          : scheme.surfaceContainer,
      shape: const StadiumBorder(),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(
              icon,
              size: 18,
              color: active ? activeColor : scheme.onSurfaceVariant,
            ),
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
