import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/garment.dart';
import '../../domain/models/garment_color.dart';
import '../providers/providers.dart';
import '../widgets/garment_image.dart';
import '../widgets/responsive.dart';

class GarmentFormScreen extends ConsumerStatefulWidget {
  const GarmentFormScreen({super.key, this.garment});

  final Garment? garment;

  @override
  ConsumerState<GarmentFormScreen> createState() => _GarmentFormScreenState();
}

class _GarmentFormScreenState extends ConsumerState<GarmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _pickedImage;
  Uint8List? _pickedBytes;
  GarmentCategory? _category;
  Occasion? _occasion;
  Season? _season;
  bool _favorite = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final garment = widget.garment;
    if (garment != null) {
      _category = garment.category;
      _occasion = garment.occasion;
      _season = garment.season;
      _favorite = garment.favorite;
      _notesController.text = garment.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.garment != null;

  Future<void> _pickFrom(ImageSource source, String errorMessage) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _pickedImage = file;
          _pickedBytes = bytes;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _pickedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una foto')));
      return;
    }
    if (_category == null || _occasion == null || _season == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa categoría, ocasión y temporada'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final imageStorage = ref.read(imageStorageProvider);
    ({String photoId, String thumbId})? saved;
    var dbWritten = false;
    try {
      final paletteExtractor = ref.read(paletteExtractorProvider);
      final repository = ref.read(garmentRepositoryProvider);

      String photoPath;
      String thumbPath;
      var colors = widget.garment?.colors ?? const [];

      if (_pickedImage != null) {
        final stored = saved = await imageStorage.save(_pickedImage!);
        photoPath = stored.photoId;
        thumbPath = stored.thumbId;
        try {
          colors = await paletteExtractor.extract(_pickedBytes!);
        } catch (_) {
          colors = const [];
        }
      } else {
        photoPath = widget.garment!.photoPath;
        thumbPath = widget.garment!.thumbPath;
      }

      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (_isEditing) {
        final updated = widget.garment!.copyWith(
          photoPath: photoPath,
          thumbPath: thumbPath,
          category: _category!,
          colors: colors,
          occasion: _occasion!,
          season: _season!,
          notes: notes,
          favorite: _favorite,
        );
        await repository.update(updated);
      } else {
        final garment = Garment(
          photoPath: photoPath,
          thumbPath: thumbPath,
          category: _category!,
          colors: colors,
          occasion: _occasion!,
          season: _season!,
          notes: notes,
          favorite: _favorite,
          createdAt: DateTime.now(),
        );
        await repository.insert(garment);
      }
      dbWritten = true;
      // Best-effort: the DB already points at the new images, so a leftover old one is harmless.
      if (_isEditing && saved != null) {
        try {
          await imageStorage.delete(
            widget.garment!.photoPath,
            widget.garment!.thumbPath,
          );
          ref.invalidate(imageBytesProvider(widget.garment!.photoPath));
          ref.invalidate(imageBytesProvider(widget.garment!.thumbPath));
        } catch (_) {}
      }

      ref.invalidate(garmentsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      // Don't leave the new images orphaned when the DB write never happened.
      if (saved != null && !dbWritten) {
        try {
          await imageStorage.delete(saved.photoId, saved.thumbId);
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la prenda. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar prenda' : 'Nueva prenda'),
      ),
      body: Form(
        key: _formKey,
        // Center via padding (not a width-capped box) so the mouse wheel also
        // scrolls when the pointer is over the side margins on desktop.
        child: Builder(
          builder: (context) {
            final side = math.max(
              16.0,
              (MediaQuery.sizeOf(context).width - 720) / 2 + 16,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(side, 8, side, 32),
              children: [
                // Phones keep the full-width photo; wider windows cap its height.
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.sizeOf(context).width >= Breakpoints.medium
                          ? 420
                          : double.infinity,
                    ),
                    child: _PhotoHero(
                      pickedBytes: _pickedBytes,
                      storedImageId: widget.garment?.thumbPath,
                      enabled: !_saving,
                      onCamera: () => _pickFrom(
                        ImageSource.camera,
                        'No se pudo abrir la cámara. Revisa los permisos.',
                      ),
                      onGallery: () => _pickFrom(
                        ImageSource.gallery,
                        'No se pudo abrir la galería.',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isEditing && widget.garment!.colors.isNotEmpty) ...[
                  _DetectedColors(colors: widget.garment!.colors),
                  const SizedBox(height: 16),
                ],
                _SectionCard(
                  icon: Icons.style_outlined,
                  title: 'Categoría',
                  child: _ChipGroup<GarmentCategory>(
                    values: GarmentCategory.values,
                    selected: _category,
                    labelOf: (v) => v.label,
                    enabled: !_saving,
                    onSelected: (v) => setState(() => _category = v),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.celebration_outlined,
                  title: 'Ocasión',
                  child: _ChipGroup<Occasion>(
                    values: Occasion.values,
                    selected: _occasion,
                    labelOf: (v) => v.label,
                    enabled: !_saving,
                    onSelected: (v) => setState(() => _occasion = v),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Temporada',
                  child: _ChipGroup<Season>(
                    values: Season.values,
                    selected: _season,
                    labelOf: (v) => v.label,
                    iconOf: _seasonIcon,
                    enabled: !_saving,
                    onSelected: (v) => setState(() => _season = v),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.favorite_border,
                  title: 'Notas y cuidados',
                  trailing: 'Opcional',
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      hintText: 'Ej: lavar a mano con agua fría…',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _FavoriteSwitch(
                  value: _favorite,
                  enabled: !_saving,
                  onChanged: (v) => setState(() => _favorite = v),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isEditing ? 'Guardar cambios' : 'Guardar prenda',
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Para eliminar esta prenda, ábrela desde el armario.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static IconData _seasonIcon(Season season) {
    switch (season) {
      case Season.summer:
        return Icons.wb_sunny_outlined;
      case Season.winter:
        return Icons.ac_unit;
      case Season.midSeason:
        return Icons.spa_outlined;
      case Season.all:
        return Icons.all_inclusive;
    }
  }
}

class _PhotoHero extends StatelessWidget {
  const _PhotoHero({
    required this.pickedBytes,
    required this.storedImageId,
    required this.enabled,
    required this.onCamera,
    required this.onGallery,
  });

  final Uint8List? pickedBytes;
  final String? storedImageId;
  final bool enabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPhoto = pickedBytes != null || storedImageId != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: scheme.surfaceContainerLowest,
                child: !hasPhoto
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: scheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Añadir foto',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : pickedBytes != null
                    ? Image.memory(
                        pickedBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                      )
                    : GarmentImage(imageId: storedImageId!),
              ),
              if (hasPhoto)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest.withValues(
                        alpha: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Foto principal',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: _PhotoAction(
                        icon: Icons.photo_camera_outlined,
                        label: 'Cámara',
                        color: scheme.primary,
                        onTap: enabled ? onCamera : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PhotoAction(
                        icon: Icons.photo_library_outlined,
                        label: 'Galería',
                        color: scheme.secondary,
                        onTap: enabled ? onGallery : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest.withValues(alpha: 0.95),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectedColors extends StatelessWidget {
  const _DetectedColors({required this.colors});

  final List<GarmentColor> colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      icon: Icons.palette_outlined,
      title: 'Colores detectados',
      trailing: '${colors.length}',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: colors
            .map(
              (c) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, c.red, c.green, c.blue),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: theme.textTheme.labelLarge)),
              if (trailing != null)
                Text(trailing!, style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChipGroup<T> extends StatelessWidget {
  const _ChipGroup({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.iconOf,
    this.enabled = true,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = value == selected;
        final icon = iconOf?.call(value);
        return ChoiceChip(
          showCheckmark: false,
          selected: isSelected,
          onSelected: enabled ? (_) => onSelected(value) : null,
          avatar: icon == null
              ? null
              : Icon(
                  icon,
                  size: 17,
                  color: isSelected
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
          label: Text(labelOf(value)),
        );
      }).toList(),
    );
  }
}

class _FavoriteSwitch extends StatelessWidget {
  const _FavoriteSwitch({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.5,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite,
              size: 22,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prenda favorita', style: theme.textTheme.labelLarge),
                Text(
                  'Aparecerá destacada en sugerencias',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}
