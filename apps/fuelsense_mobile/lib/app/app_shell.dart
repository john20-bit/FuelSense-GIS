import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/app_motion.dart';
import '../core/design/app_theme_extension.dart';
import '../core/design/design_tokens.dart';
import '../core/widgets/app_background.dart';
import '../features/home/screens/home_screen.dart';
import '../features/fuel_quality/screens/fuel_quality_screen.dart';
import '../features/garage/presentation/garage_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/spatial/screens/spatial_mapping_screen.dart';
import 'app_shell_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _pages = [
    HomeScreen(),
    SpatialMappingScreen(),
    GarageScreen(),
    FuelQualityScreen(),
    SettingsScreen(),
  ];

  static const _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItemData(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'Map',
    ),
    _NavItemData(
      icon: Icons.directions_car_outlined,
      activeIcon: Icons.directions_car_filled_rounded,
      label: 'Vehicle',
    ),
    _NavItemData(
      icon: Icons.monitor_heart_outlined,
      activeIcon: Icons.monitor_heart_rounded,
      label: 'Monitoring',
    ),
    _NavItemData(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (currentIndex != 0) {
          ref.read(homeTabIndexProvider.notifier).setIndex(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: context.fuelTheme.background,
        body: Stack(
          children: [
            const AppBackground(),
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
                        begin: const Offset(0.015, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(currentIndex),
                  child: _pages[currentIndex],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            FuelSenseDesignTokens.space12,
            0,
            FuelSenseDesignTokens.space12,
            FuelSenseDesignTokens.space12,
          ),
          child: _FuelSenseNavigation(
            currentIndex: currentIndex,
            items: _items,
            onTap: (index) {
              if (index == currentIndex) return;

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

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: theme.surfaceElevated.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(FuelSenseDesignTokens.radiusXl),
          border: Border.all(color: theme.borderStrong.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.32
                    : 0.10,
              ),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];

            return Expanded(
              child: _NavigationItem(
                item: item,
                selected: index == currentIndex,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
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
    final theme = context.fuelTheme;

    final activeColor = theme.accent;

    final inactiveColor = theme.textMuted.withValues(alpha: 0.82);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FuelSenseDesignTokens.radiusLg),
          splashColor: activeColor.withValues(alpha: 0.08),
          highlightColor: activeColor.withValues(alpha: 0.04),
          child: SizedBox(
            height: 62,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standardCurve,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: selected
                    ? activeColor.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  FuelSenseDesignTokens.radiusLg,
                ),
                border: Border.all(
                  color: selected
                      ? activeColor.withValues(alpha: 0.18)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.standardCurve,
                    width: selected ? 22 : 0,
                    height: 2.5,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(
                        FuelSenseDesignTokens.radiusPill,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    switchInCurve: AppMotion.standardCurve,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      selected ? item.activeIcon : item.icon,
                      key: ValueKey('${item.label}-$selected'),
                      size: selected ? 22 : 21,
                      color: selected ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: AppMotion.fast,
                    curve: AppMotion.standardCurve,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? activeColor : inactiveColor,
                      letterSpacing: 0.15,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
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
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
