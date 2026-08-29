import 'package:flutter/material.dart';

import '../../core/storage/secure_storage.dart';

/// Manages the app's theme brightness (light / dark / system) and persists the
/// user's choice so it survives restarts.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider();

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  bool get isDark {
    return switch (_mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark,
    };
  }

  /// Reads the persisted theme mode (called once at startup).
  Future<void> load() async {
    try {
      final raw = await SecureStorage.readThemeMode();
      _mode = _parse(raw) ?? ThemeMode.system;
    } catch (_) {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Sets the theme mode and persists it.
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await SecureStorage.saveThemeMode(
        switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        },
      );
    } catch (_) {
      // Persistence is best-effort; the in-memory mode still applies.
    }
  }

  /// Flips between light and dark (accounting for the current system mode).
  Future<void> toggle() async {
    final platformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    final next = switch (_mode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      // In system mode, flip to the opposite of the current platform brightness.
      ThemeMode.system => platformDark ? ThemeMode.light : ThemeMode.dark,
    };
    await setMode(next);
  }

  static ThemeMode? _parse(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => null,
    };
  }
}
