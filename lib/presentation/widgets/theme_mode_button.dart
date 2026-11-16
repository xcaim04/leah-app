import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// App bar action to pick the theme: Sistema / Claro / Oscuro.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  static const Map<ThemeMode, (String, IconData)> _options = {
    ThemeMode.system: ('Sistema', Icons.brightness_auto_outlined),
    ThemeMode.light: ('Claro', Icons.light_mode_outlined),
    ThemeMode.dark: ('Oscuro', Icons.dark_mode_outlined),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final (label, icon) = _options[mode]!;

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Tema: $label',
      icon: Icon(icon),
      initialValue: mode,
      onSelected: (value) => ref.read(themeModeProvider.notifier).set(value),
      itemBuilder: (context) => [
        for (final MapEntry(key: value, value: (text, itemIcon))
            in _options.entries)
          CheckedPopupMenuItem(
            value: value,
            checked: value == mode,
            child: Row(
              children: [
                Icon(itemIcon, size: 20),
                const SizedBox(width: 12),
                Text(text),
              ],
            ),
          ),
      ],
    );
  }
}
