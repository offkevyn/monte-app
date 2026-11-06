import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/storage/app_preferences.dart';
import 'package:monte/core/theme/theme_controller.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'shared preferences start with safe defaults and remember changes',
    () async {
      final prefs = SharedAppPreferences();
      expect(await prefs.biometricsEnabled(), isFalse);
      expect(await prefs.biometricsOfferShown(), isFalse);
      expect(await prefs.hideBalance(), isFalse);
      expect(await prefs.balanceNeedsBiometrics(), isFalse);
      expect(await prefs.themeMode(), 'system');

      await prefs.setBiometricsEnabled(enabled: true);
      await prefs.markBiometricsOfferShown();
      await prefs.setHideBalance(hidden: true);
      await prefs.setBalanceNeedsBiometrics(enabled: true);
      await prefs.setThemeMode('dark');

      // A new instance reads what the previous one saved (between sessions).
      final again = SharedAppPreferences();
      expect(await again.biometricsEnabled(), isTrue);
      expect(await again.biometricsOfferShown(), isTrue);
      expect(await again.hideBalance(), isTrue);
      expect(await again.balanceNeedsBiometrics(), isTrue);
      expect(await again.themeMode(), 'dark');
    },
  );

  group('ThemeController', () {
    test('loads the saved mode and ignores unknown values', () async {
      final prefs = MemoryAppPreferences()..theme = 'dark';
      final controller = ThemeController(prefs);
      await controller.load();
      expect(controller.value, ThemeMode.dark);

      prefs.theme = 'purple';
      await controller.load();
      expect(controller.value, ThemeMode.system);
    });

    test('toggle flips what is on screen and saves it', () async {
      final prefs = MemoryAppPreferences();
      final controller = ThemeController(prefs);
      await controller.toggle(Brightness.light);
      expect(controller.value, ThemeMode.dark);
      expect(prefs.theme, 'dark');
      await controller.toggle(Brightness.dark);
      expect(controller.value, ThemeMode.light);
    });
  });
}
