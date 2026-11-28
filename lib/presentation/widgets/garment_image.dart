import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// A garment photo stored in the DB (`imageId` from `photoPath`/`thumbPath`).
class GarmentImage extends ConsumerWidget {
  const GarmentImage({
    super.key,
    required this.imageId,
    this.cacheWidth,
    this.fit = BoxFit.cover,
  });

  final String imageId;
  final int? cacheWidth;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.checkroom_outlined, color: scheme.onSurfaceVariant),
      ),
    );
    return ref
        .watch(imageBytesProvider(imageId))
        .when(
          loading: () => ColoredBox(color: scheme.surfaceContainer),
          error: (_, _) => fallback,
          data: (bytes) => bytes == null
              ? fallback
              : Image.memory(
                  bytes,
                  fit: fit,
                  cacheWidth: cacheWidth,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => fallback,
                ),
        );
  }
}
