import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/outfit.dart';
import '../providers/providers.dart';

const _cardW = 1080.0;
const _cardH = 1350.0;

/// Renders [outfit] as a 1080x1350 PNG card and opens the system share sheet
/// (on web share_plus falls back to a download when file sharing is unsupported).
Future<void> shareOutfit(
  BuildContext context,
  WidgetRef ref,
  Outfit outfit,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final overlay = Overlay.of(context, rootOverlay: true);
  final theme = Theme.of(context);
  final storage = ref.read(imageStorageProvider);
  OverlayEntry? entry;
  try {
    final images = <MemoryImage?>[];
    for (final g in outfit.garments) {
      var bytes = await storage.load(g.photoPath);
      bytes ??= await storage.load(g.thumbPath);
      images.add(bytes == null ? null : MemoryImage(bytes));
    }
    if (!context.mounted) return;
    for (final img in images.whereType<MemoryImage>()) {
      await precacheImage(img, context);
    }
    if (!context.mounted) return;

    final key = GlobalKey();
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: 0,
        width: _cardW,
        height: _cardH,
        child: IgnorePointer(
          child: RepaintBoundary(
            key: key,
            child: Theme(
              data: theme,
              child: _LookCard(images: images, explanation: outfit.explanation),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final png = data!.buffer.asUint8List();

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(png, mimeType: 'image/png', name: 'mi-look.png'),
        ],
        fileNameOverrides: const ['mi-look.png'],
        text: outfit.explanation,
      ),
    );
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('No se pudo compartir el look')),
    );
  } finally {
    entry?.remove();
    entry?.dispose();
  }
}

class _LookCard extends StatelessWidget {
  const _LookCard({required this.images, required this.explanation});

  final List<MemoryImage?> images;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cols = images.length <= 2
        ? images.length.clamp(1, 2)
        : (images.length <= 6 ? 3 : 4);
    const gap = 24.0;
    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mi look',
              style: tt.displayMedium?.copyWith(
                fontSize: 80,
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final img in images)
                      SizedBox(
                        width: (_cardW - 144 - gap * (cols - 1)) / cols,
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: img == null
                                ? ColoredBox(
                                    color: cs.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.checkroom,
                                      size: 96,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  )
                                : Image(image: img, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              explanation,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: tt.titleLarge?.copyWith(fontSize: 36, color: cs.onSurface),
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Mi Armario',
                style: tt.titleMedium?.copyWith(
                  fontSize: 30,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
