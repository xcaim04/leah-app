import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_shell.dart';

class MiArmarioApp extends StatelessWidget {
  const MiArmarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Armario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      home: const AppShell(),
    );
  }
}
