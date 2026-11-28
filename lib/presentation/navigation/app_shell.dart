import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/outfit_providers.dart';
import '../screens/diary_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/outfits_screen.dart';
import '../screens/wardrobe_screen.dart';
import '../widgets/responsive.dart';

/// Root scaffold: bottom navigation bar on phones, navigation rail on wide windows.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  // Keeps the tabs' state when a resize swaps the bar for the rail.
  final _bodyKey = GlobalKey();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The look of the day depends on today's date; refresh after midnight.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(lookOfTheDayProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  static const List<Widget> _screens = [
    WardrobeScreen(),
    OutfitsScreen(),
    FavoritesScreen(),
    DiaryScreen(),
  ];

  static const _destinations = [
    (Icons.checkroom_outlined, Icons.checkroom, 'Armario'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, 'Looks'),
    (Icons.favorite_border, Icons.favorite, 'Favoritos'),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'Diario'),
  ];

  void _select(int value) => setState(() => _index = value);

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(key: _bodyKey, index: _index, children: _screens);
    final width = MediaQuery.sizeOf(context).width;

    if (width >= Breakpoints.expanded) {
      final scheme = Theme.of(context).colorScheme;
      final extended = width >= Breakpoints.large;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              extended: extended,
              minExtendedWidth: 200,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              backgroundColor: scheme.surface,
              indicatorColor: scheme.secondaryContainer,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: extended
                    ? Text(
                        'Mi Armario',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.primary),
                      )
                    : Icon(Icons.checkroom, color: scheme.primary),
              ),
              destinations: [
                for (final (icon, selected, label) in _destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (final (icon, selected, label) in _destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
