import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/app_theme_extension.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.fuelTheme;
    final controller = ref.watch(themeControllerProvider);

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          const AppBackground(),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                Row(
                  children: [
                    _IconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'APP CONTROL',
                            style: TextStyle(
                              color: theme.accent,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Settings',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _SectionLabel(title: 'APPEARANCE', color: theme.textMuted),

                const SizedBox(height: 10),

                _SettingsCard(
                  child: Column(
                    children: FuelSenseThemeMode.values.map((mode) {
                      return _ThemeOption(
                        mode: mode,
                        selected: controller.mode == mode,
                        onTap: () {
                          ref.read(themeControllerProvider).setMode(mode);
                        },
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                _SectionLabel(title: 'ACCOUNT', color: theme.textMuted),

                const SizedBox(height: 10),

                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Manage alerts and vehicle updates',
                ),

                const SizedBox(height: 10),

                _SettingsRow(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'Choose your preferred language',
                ),

                const SizedBox(height: 10),

                _SettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'Privacy & Security',
                  subtitle: 'Session and data controls',
                ),

                const SizedBox(height: 28),

                Center(
                  child: Text(
                    'FUEL SENSE • ENERGY MOBILITY INTELLIGENCE',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final FuelSenseThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.accent.withValues(alpha: 0.12)
                      : theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? theme.accent.withValues(alpha: 0.35)
                        : theme.border,
                  ),
                ),
                child: Icon(
                  mode.icon,
                  color: selected ? theme.accent : theme.textMuted,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      mode.description,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? theme.accent : theme.borderStrong,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.accent,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.border),
      ),
      child: child,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return _SettingsCard(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.accent, size: 20),
        ),

        title: Text(
          title,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        subtitle: Text(
          subtitle,
          style: TextStyle(color: theme.textSecondary, fontSize: 11),
        ),

        trailing: Icon(Icons.chevron_right_rounded, color: theme.textMuted),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: theme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.border),
        ),
        child: Icon(icon, color: theme.textPrimary, size: 20),
      ),
    );
  }
}
