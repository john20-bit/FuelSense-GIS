import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FuelSenseThemeMode { system, light, dark, fuelSense }

extension FuelSenseThemeModeX on FuelSenseThemeMode {
  String get label {
    switch (this) {
      case FuelSenseThemeMode.system:
        return 'System Default';
      case FuelSenseThemeMode.light:
        return 'Light';
      case FuelSenseThemeMode.dark:
        return 'Dark';
      case FuelSenseThemeMode.fuelSense:
        return 'FuelSense';
    }
  }

  String get description {
    switch (this) {
      case FuelSenseThemeMode.system:
        return 'Follow your device appearance';
      case FuelSenseThemeMode.light:
        return 'Clean bright interface';
      case FuelSenseThemeMode.dark:
        return 'Deep dark interface';
      case FuelSenseThemeMode.fuelSense:
        return 'Signature FuelSense interface';
    }
  }

  IconData get icon {
    switch (this) {
      case FuelSenseThemeMode.system:
        return Icons.brightness_auto_rounded;
      case FuelSenseThemeMode.light:
        return Icons.light_mode_rounded;
      case FuelSenseThemeMode.dark:
        return Icons.dark_mode_rounded;
      case FuelSenseThemeMode.fuelSense:
        return Icons.bolt_rounded;
    }
  }
}

class ThemeController extends ChangeNotifier {
  static const String _storageKey = 'fuelsense_theme_mode';

  FuelSenseThemeMode _mode = FuelSenseThemeMode.fuelSense;

  FuelSenseThemeMode get mode => _mode;

  ThemeMode get materialThemeMode {
    switch (_mode) {
      case FuelSenseThemeMode.system:
        return ThemeMode.system;
      case FuelSenseThemeMode.light:
        return ThemeMode.light;
      case FuelSenseThemeMode.dark:
      case FuelSenseThemeMode.fuelSense:
        return ThemeMode.dark;
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);

      if (saved == null) return;

      _mode = FuelSenseThemeMode.values.firstWhere(
        (value) => value.name == saved,
        orElse: () => FuelSenseThemeMode.fuelSense,
      );

      notifyListeners();
    } catch (_) {
      _mode = FuelSenseThemeMode.fuelSense;
    }
  }

  Future<void> setMode(FuelSenseThemeMode mode) async {
    if (_mode == mode) return;

    _mode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, mode.name);
    } catch (_) {
      // Keep the in-memory theme if persistence fails.
    }
  }
}

final themeControllerProvider = ChangeNotifierProvider<ThemeController>((ref) {
  final controller = ThemeController();
  controller.load();
  return controller;
});
