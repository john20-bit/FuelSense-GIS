import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/app_motion.dart';
import '../features/home/screens/home_screen.dart';
import '../features/spatial/screens/spatial_mapping_screen.dart';
import '../features/garage/presentation/garage_screen.dart';
import '../features/fuel_quality/screens/fuel_quality_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import 'app_shell_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const Color _black = Color(0xFF050709);
  static const Color _panel = Color(0xF20B1015);
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _green = Color(0xFF39FF88);
  static const Color _violet = Color(0xFFB56BFF);
  static const Color _text = Color(0xFFF2F7FA);
  static const Color _muted = Color(0xFF8B9AA5);
  static const Color _border = Color(0xFF26343E);

  static const List<Widget> _pages = [
    HomeScreen(),
    SpatialMappingScreen(),
    GarageScreen(),
    FuelQualityScreen(),
    SettingsScreen(),
  ];

  static const List<_NavItemData> _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      color: _cyan,
    ),
    _NavItemData(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'Map',
      color: _green,
    ),
    _NavItemData(
      icon: Icons.directions_car_outlined,
      activeIcon: Icons.directions_car_filled_rounded,
      label: 'Garage',
      color: _violet,
    ),
    _NavItemData(
      icon: Icons.monitor_heart_outlined,
      activeIcon: Icons.monitor_heart_rounded,
      label: 'Monitor',
      color: _cyan,
    ),
    _NavItemData(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      color: _green,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);
    final safeIndex = currentIndex.clamp(0, _pages.length - 1);

    return PopScope(
      canPop: safeIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (safeIndex != 0) {
          ref.read(homeTabIndexProvider.notifier).setIndex(0);
        }
      },
      child: Scaffold(
        backgroundColor: _black,
        extendBody: true,
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.75),
                    radius: 1.35,
                    colors: [Color(0xFF101C24), _black],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: AppMotion.standardCurve,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.025, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(safeIndex),
                  child: _pages[safeIndex],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: _FuelSenseNavigation(
            currentIndex: safeIndex,
            items: _items,
            onTap: (index) {
              if (index == safeIndex) return;
              ref.read(homeTabIndexProvider.notifier).setIndex(index);
            },
          ),
        ),
      ),
    );
  }
}

class _FuelSenseNavigation extends StatelessWidget {
  const _FuelSenseNavigation({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<_NavItemData> items;
  final ValueChanged<int> onTap;

  static const Color _panel = Color(0xF20B1015);
  static const Color _border = Color(0xFF26343E);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.035),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          return Expanded(
            child: _NavigationItem(
              item: items[index],
              selected: index == currentIndex,
              onTap: () => onTap(index),
            ),
          );
        }),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = item.color;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          splashColor: accent.withValues(alpha: 0.12),
          highlightColor: accent.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standardCurve,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.20)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: selected ? 18 : 0,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      if (selected)
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 7,
                        ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    key: ValueKey('${item.label}-$selected'),
                    size: selected ? 22 : 21,
                    color: selected ? accent : const Color(0xFF8B9AA5),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: AppMotion.fast,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: 0.15,
                    color: selected ? accent : const Color(0xFFF2F7FA).withValues(alpha: 0.65),
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
}

