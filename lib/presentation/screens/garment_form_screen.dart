import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/garment.dart';
import '../providers/providers.dart';

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

  String? _pickedImagePath;
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

  Future<void> _pickImage() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Cámara'),
              onTap: () async {
                Navigator.of(context).pop();
                final file = await _picker.pickImage(source: ImageSource.camera);
                if (file != null && mounted) {
                  setState(() => _pickedImagePath = file.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () async {
                Navigator.of(context).pop();
                final file = await _picker.pickImage(source: ImageSource.gallery);
                if (file != null && mounted) {
                  setState(() => _pickedImagePath = file.path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _pickedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una foto')),
      );
      return;
    }
    if (_category == null || _occasion == null || _season == null) return;

    setState(() => _saving = true);
    try {
      final imageStorage = ref.read(imageStorageProvider);
      final paletteExtractor = ref.read(paletteExtractorProvider);
      final repository = ref.read(garmentRepositoryProvider);

      String photoPath;
      String thumbPath;
      var colors = widget.garment?.colors ?? const [];

      if (_pickedImagePath != null) {
        final saved = await imageStorage.save(_pickedImagePath!);
        photoPath = saved.photoPath;
        thumbPath = saved.thumbPath;
        colors = await paletteExtractor.extract(photoPath);
        if (_isEditing) {
          await imageStorage.delete(
            widget.garment!.photoPath,
            widget.garment!.thumbPath,
          );
        }
      } else {
        photoPath = widget.garment!.photoPath;
        thumbPath = widget.garment!.thumbPath;
      }

      if (_isEditing) {
        final updated = widget.garment!.copyWith(
          photoPath: photoPath,
          thumbPath: thumbPath,
          category: _category!,
          colors: colors,
          occasion: _occasion!,
          season: _season!,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
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
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          favorite: _favorite,
          createdAt: DateTime.now(),
        );
        await repository.insert(garment);
      }

      ref.invalidate(garmentsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la prenda: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewPath = _pickedImagePath ?? widget.garment?.thumbPath;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar prenda' : 'Nueva prenda'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _saving ? null : _pickImage,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: previewPath == null
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 40),
                              SizedBox(height: 8),
                              Text('Agregar foto'),
                            ],
                          ),
                        )
                      : Image.file(
                          File(previewPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image_outlined)),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GarmentCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: GarmentCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Selecciona una categoría' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Occasion>(
              value: _occasion,
              decoration: const InputDecoration(labelText: 'Ocasión'),
              items: Occasion.values
                  .map((o) => DropdownMenuItem(value: o, child: Text(o.label)))
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _occasion = v),
              validator: (v) => v == null ? 'Selecciona una ocasión' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Season>(
              value: _season,
              decoration: const InputDecoration(labelText: 'Temporada'),
              items: Season.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _season = v),
              validator: (v) => v == null ? 'Selecciona una temporada' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 3,
              enabled: !_saving,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Favorito'),
              value: _favorite,
              onChanged: _saving ? null : (v) => setState(() => _favorite = v),
            ),
          ],
        ),
      ),
    );
  }
}
