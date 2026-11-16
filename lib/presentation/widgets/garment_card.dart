import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/garment.dart';

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(garment.thumbPath),
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Material(
                      color: theme.colorScheme.surface.withValues(alpha: 0.75),
                      shape: const CircleBorder(),
                      child: Tooltip(
                        message: garment.favorite
                            ? 'Quitar de favoritos'
                            : 'Marcar como favorito',
                        child: Semantics(
                          button: true,
                          label: garment.favorite
                              ? 'Quitar de favoritos'
                              : 'Marcar como favorito',
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onFavoriteToggle,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                garment.favorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: garment.favorite
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    garment.category.label,
                    style: theme.textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (garment.colors.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: garment.colors
                          .take(5)
                          .map(
                            (c) => Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, c.red, c.green, c.blue),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
