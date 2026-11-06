import 'package:shared_preferences/shared_preferences.dart';

/// User choices that are not secrets (on/off switches). They live in
/// shared_preferences; anything sensitive goes to `SecureStore` instead.
abstract interface class AppPreferences {
  Future<bool> biometricsEnabled();

  Future<void> setBiometricsEnabled({required bool enabled});

  /// Whether the "use your fingerprint?" offer was already shown once.
  Future<bool> biometricsOfferShown();

  Future<void> markBiometricsOfferShown();
}

final class SharedAppPreferences implements AppPreferences {
  SharedAppPreferences([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _biometrics = 'monte.biometrics_enabled';
  static const _offerShown = 'monte.biometrics_offer_shown';

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
}

/// In-memory preferences for tests.
final class MemoryAppPreferences implements AppPreferences {
  bool biometrics = false;
  bool offerShown = false;

  @override
  Future<bool> biometricsEnabled() async => biometrics;

  @override
  Future<void> setBiometricsEnabled({required bool enabled}) async =>
      biometrics = enabled;

  @override
  Future<bool> biometricsOfferShown() async => offerShown;

  @override
  Future<void> markBiometricsOfferShown() async => offerShown = true;
}
