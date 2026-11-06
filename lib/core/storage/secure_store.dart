import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small secrets that must survive app restarts but never sit in plain
/// files: the database key now, the session token later.
///
/// On Android values are encrypted with a key held by the Android Keystore
/// (hardware backed when available); on iOS they go to the Keychain. This is
/// why they do not go to shared_preferences, which is a plain XML file.
abstract interface class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

final class PlatformSecureStore implements SecureStore {
  const PlatformSecureStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory store for tests and for the dev flavor on desktop.
final class MemorySecureStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
