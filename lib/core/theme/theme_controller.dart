import 'package:flutter/material.dart';

import '../storage/app_preferences.dart';

/// Light, dark or follow the system; saved between sessions.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(this._preferences) : super(ThemeMode.system);

  final AppPreferences _preferences;

  Future<void> load() async {
    value =
        ThemeMode.values.asNameMap()[await _preferences.themeMode()] ??
        ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    value = mode;
    await _preferences.setThemeMode(mode.name);
  }

  /// The moon/sun button in the dashboard header: flips what is on screen.
  Future<void> toggle(Brightness current) =>
      set(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}
