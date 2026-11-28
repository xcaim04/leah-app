import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/backup/backup_service.dart';
import '../providers/providers.dart';
import '../widgets/responsive.dart';

const lastBackupKey = 'last_backup_at';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  String _last = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    final raw = await ref.read(settingsRepositoryProvider).get(lastBackupKey);
    final at = raw == null ? null : DateTime.tryParse(raw);
    if (!mounted) return;
    setState(() {
      if (at == null) {
        _last = 'Última copia: nunca';
      } else {
        final d = DateTime.now().difference(at).inDays;
        _last = d <= 0
            ? 'Última copia: hoy'
            : 'Última copia: hace $d ${d == 1 ? 'día' : 'días'}';
      }
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(backupServiceProvider).export();
      final now = DateTime.now();
      final name =
          'mi-armario-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, mimeType: 'application/json', name: name),
          ],
          fileNameOverrides: [name],
        ),
      );
      await ref
          .read(settingsRepositoryProvider)
          .set(lastBackupKey, now.toIso8601String());
      await _loadLast();
    } catch (_) {
      if (mounted) _snack('No se pudo exportar la copia.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Importar copia'),
          content: const Text(
            'Se reemplazarán todas tus prendas y looks por los de la copia. ¿Continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(backupServiceProvider).import(bytes);
      ref.invalidate(garmentsProvider);
      ref.invalidate(outfitFeedbackProvider);
      ref.invalidate(imageBytesProvider);
      ref.invalidate(wearLogProvider);
      if (mounted) _snack('Copia restaurada');
    } on BackupException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('No se pudo importar la copia.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Copia de seguridad')),
      body: ContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Tus prendas y looks se guardan solo en este dispositivo (o navegador). '
              'Exporta una copia con regularidad para no perderlos.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(_last, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_file),
              label: const Text('Exportar copia'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download),
              label: const Text('Importar copia'),
            ),
          ],
        ),
      ),
    );
  }
}
