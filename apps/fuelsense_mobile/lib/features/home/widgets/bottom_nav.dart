import 'package:flutter/material.dart';

/// Legacy compatibility widget.
///
/// AppShell now owns the application's bottom navigation.
/// This widget remains temporarily so older imports do not break.
@Deprecated('Use AppShell navigation instead.')
class FuelBottomNav extends StatelessWidget {
  const FuelBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
