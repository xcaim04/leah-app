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
    final scorePct = (outfit.score * 100).round();
    final ratings = ref.watch(latestRatingsProvider);
    final rating = ratings[outfit.signature];
    final controller = ref.read(feedbackControllerProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in outfit.garments) _GarmentChip(garment: g),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ScoreBadge(scorePct: scorePct),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              outfit.explanation,
              style: theme.textTheme.bodyMedium,
            ),
            if (showFeedback) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Me gusta',
                    onPressed: () => controller.like(outfit),
                    icon: Icon(
                      rating == FeedbackRating.like
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      color: rating == FeedbackRating.like
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    tooltip: 'No me gusta',
                    onPressed: () => controller.dislike(outfit),
                    icon: Icon(
                      rating == FeedbackRating.dislike
                          ? Icons.thumb_down
                          : Icons.thumb_down_outlined,
                      color: rating == FeedbackRating.dislike
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GarmentChip extends StatelessWidget {
  const _GarmentChip({required this.garment});

  final Garment garment;

  @override
  Widget build(BuildContext context) {
    final color = garment.colors.isNotEmpty
        ? Color.fromARGB(
            255,
            garment.colors.first.red,
            garment.colors.first.green,
            garment.colors.first.blue,
          )
        : Theme.of(context).colorScheme.outline;
    return Chip(
      avatar: CircleAvatar(backgroundColor: color),
      label: Text(garment.category.label),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.scorePct});

  final int scorePct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$scorePct%',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
