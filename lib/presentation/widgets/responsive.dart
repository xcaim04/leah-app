import 'package:flutter/material.dart';

/// Material 3 window size classes (compact < 600 ≤ medium < 840 ≤ expanded).
class Breakpoints {
  Breakpoints._();

  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;
}

/// Centers [child] and caps its width so content never stretches across a
/// desktop window. On phones it is a no-op.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 1100});

  /// Typical values: 1100 for grids, 720 for reading/forms, 560 for dialogs-like pages.
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}
