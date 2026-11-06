import 'dart:io';
import 'dart:math';

import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import 'secure_store.dart';

/// Creates (once) and returns the random key of the local database.
///
/// 32 bytes from the platform's secure random generator, hex encoded. The
/// key never leaves the secure store and is never logged.
final class DatabaseKeyProvider {
  DatabaseKeyProvider(this._store, {Random? random})
    : _random = random ?? Random.secure();

  static const storageKey = 'monte.database_key.v1';

  final SecureStore _store;
  final Random _random;

  Future<String> obtain() async {
    final existing = await _store.read(storageKey);
    if (existing != null && EncryptedDatabase.isValidKey(existing)) {
      return existing;
    }
    final key = List.generate(
      32,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _store.write(storageKey, key);
    return key;
  }
}

/// Helpers to open the SQLite3MultipleCiphers database safely.
abstract final class EncryptedDatabase {
  static final _keyPattern = RegExp(r'^[0-9a-f]{64}$');

  static bool isValidKey(String key) => _keyPattern.hasMatch(key);

  /// Checked on a throwaway in-memory database: on an encrypted file, any
  /// statement run before the key fails with "file is not a database".
  static final bool _hasCipherSupport = () {
    final probe = sqlite3.openInMemory();
    try {
      probe.select('SELECT sqlite3mc_version()');
      return true;
    } on SqliteException {
      return false;
    } finally {
      probe.close();
    }
  }();

  /// Unlocks [db] with [hexKey]. Runs as drift's `setup` callback, before any
  /// query.
  ///
  /// Refuses to continue when the bundled SQLite has no encryption support,
  /// so a build misconfiguration can never silently write bank data in
  /// plain text.
  static void unlock(CommonDatabase db, String hexKey) {
    if (!isValidKey(hexKey)) {
      throw ArgumentError('Database key must be 64 hex characters');
    }
    if (!_hasCipherSupport) {
      throw StateError('SQLite was built without encryption support');
    }
    // The key is hex only (checked above), so it is safe to inline.
    db.execute("PRAGMA key = '$hexKey'");
    // Fails with "file is not a database" when the key does not match.
    db.select('SELECT count(*) FROM sqlite_master');
  }

  /// Makes sure the file at [path] opens with [hexKey]. If it does not (the
  /// key was lost, e.g. after restoring a backup on a new phone), the file is
  /// deleted: it is only a cache and the server has the data.
  ///
  /// Returns whether an unreadable file had to be discarded.
  static bool prepareFile(String path, String hexKey) {
    final file = File(path);
    if (!file.existsSync()) return false;
    final db = sqlite3.open(path);
    var readable = false;
    try {
      unlock(db, hexKey);
      readable = true;
    } on SqliteException {
      // Wrong key or not a database: handled below.
    } finally {
      db.close();
    }
    if (readable) return false;

    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final part = File('$path$suffix');
      if (part.existsSync()) part.deleteSync();
    }
    return true;
  }
}
