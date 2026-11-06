import 'package:shared_preferences/shared_preferences.dart';

/// User choices that are not secrets (on/off switches). They live in
/// shared_preferences; anything sensitive goes to `SecureStore` instead.
abstract interface class AppPreferences {
  Future<bool> biometricsEnabled();

  Future<void> setBiometricsEnabled({required bool enabled});

  /// Whether the "use your fingerprint?" offer was already shown once.
  Future<bool> biometricsOfferShown();

  Future<void> markBiometricsOfferShown();

  /// Balance shown blurred; kept between sessions as the requirements ask.
  Future<bool> hideBalance();

  Future<void> setHideBalance({required bool hidden});

  /// Ask for the fingerprint before showing a hidden balance.
  Future<bool> balanceNeedsBiometrics();

  Future<void> setBalanceNeedsBiometrics({required bool enabled});

  /// `light`, `dark` or `system`.
  Future<String> themeMode();

  Future<void> setThemeMode(String mode);
}

final class SharedAppPreferences implements AppPreferences {
  SharedAppPreferences([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _biometrics = 'monte.biometrics_enabled';
  static const _offerShown = 'monte.biometrics_offer_shown';
  static const _hideBalance = 'monte.hide_balance';
  static const _balanceBiometrics = 'monte.balance_biometrics';
  static const _theme = 'monte.theme_mode';

  @override
  Future<bool> biometricsEnabled() async =>
      await _prefs.getBool(_biometrics) ?? false;

  @override
  Future<void> setBiometricsEnabled({required bool enabled}) =>
      _prefs.setBool(_biometrics, enabled);

  @override
  Future<bool> biometricsOfferShown() async =>
      await _prefs.getBool(_offerShown) ?? false;

  @override
  Future<void> markBiometricsOfferShown() => _prefs.setBool(_offerShown, true);

  @override
  Future<bool> hideBalance() async =>
      await _prefs.getBool(_hideBalance) ?? false;

  @override
  Future<void> setHideBalance({required bool hidden}) =>
      _prefs.setBool(_hideBalance, hidden);

  @override
  Future<bool> balanceNeedsBiometrics() async =>
      await _prefs.getBool(_balanceBiometrics) ?? false;

  @override
  Future<void> setBalanceNeedsBiometrics({required bool enabled}) =>
      _prefs.setBool(_balanceBiometrics, enabled);

  @override
  Future<String> themeMode() async =>
      await _prefs.getString(_theme) ?? 'system';

  @override
  Future<void> setThemeMode(String mode) => _prefs.setString(_theme, mode);
}

/// In-memory preferences for tests.
final class MemoryAppPreferences implements AppPreferences {
  bool biometrics = false;
  bool offerShown = false;
  bool hidden = false;
  bool balanceBiometrics = false;
  String theme = 'system';

  @override
  Future<bool> biometricsEnabled() async => biometrics;

  @override
  Future<void> setBiometricsEnabled({required bool enabled}) async =>
      biometrics = enabled;

  @override
  Future<bool> biometricsOfferShown() async => offerShown;

  @override
  Future<void> markBiometricsOfferShown() async => offerShown = true;

  @override
  Future<bool> hideBalance() async => hidden;

  @override
  Future<void> setHideBalance({required bool hidden}) async =>
      this.hidden = hidden;

  @override
  Future<bool> balanceNeedsBiometrics() async => balanceBiometrics;

  @override
  Future<void> setBalanceNeedsBiometrics({required bool enabled}) async =>
      balanceBiometrics = enabled;

  @override
  Future<String> themeMode() async => theme;

  @override
  Future<void> setThemeMode(String mode) async => theme = mode;
}
