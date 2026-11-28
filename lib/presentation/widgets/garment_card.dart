import 'package:flutter/material.dart';

import '../../domain/models/garment.dart';
import 'garment_image.dart';

class GarmentCard extends StatelessWidget {
  const GarmentCard({
    super.key,
    required this.garment,
    this.onTap,
    this.onFavoriteToggle,
  });

  final Garment garment;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GarmentImage(imageId: garment.thumbPath, cacheWidth: 600),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: _FavoriteButton(
                          favorite: garment.favorite,
                          onTap: onFavoriteToggle,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        garment.occasion.label,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (garment.colors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: garment.colors
                              .take(5)
                              .map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(
                                        255,
                                        c.red,
                                        c.green,
                                        c.blue,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: scheme.surfaceContainerLowest,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.favorite, this.onTap});

  final bool favorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = favorite ? 'Quitar de favoritos' : 'Marcar como favorito';

    // 48dp hit area around the 34dp visual circle.
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: favorite ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
