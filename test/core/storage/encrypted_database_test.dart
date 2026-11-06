import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/storage/encrypted_database.dart';
import 'package:monte/core/storage/secure_store.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  final keyA = 'a' * 64;
  final keyB = 'b' * 64;
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('monte_db_');
    path = p.join(dir.path, 'ledger.db');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  void writeSecret(String key, String secret) {
    final db = sqlite3.open(path);
    EncryptedDatabase.unlock(db, key);
    db
      ..execute('CREATE TABLE t (v TEXT)')
      ..execute('INSERT INTO t VALUES (?)', [secret]);
    db.close();
  }

  group('EncryptedDatabase', () {
    test('the file on disk does not contain the data in plain text', () {
      writeSecret(keyA, 'Padaria São José R\$ 12,90');

      final bytes = File(path).readAsBytesSync();
      expect(String.fromCharCodes(bytes), isNot(contains('Padaria')));
      // A plain SQLite file starts with this header; an encrypted one does not.
      expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));
    });

    test('opens with the right key', () {
      writeSecret(keyA, 'hello');
      final db = sqlite3.open(path);
      EncryptedDatabase.unlock(db, keyA);
      expect(db.select('SELECT v FROM t').single['v'], 'hello');
      db.close();
    });

    test('refuses the wrong key', () {
      writeSecret(keyA, 'hello');
      final db = sqlite3.open(path);
      expect(
        () => EncryptedDatabase.unlock(db, keyB),
        throwsA(isA<SqliteException>()),
      );
      db.close();
    });

    test('rejects keys that are not 64 hex characters', () {
      final db = sqlite3.openInMemory();
      for (final bad in ['', 'abc', 'g' * 64, "${'a' * 63}'"]) {
        expect(() => EncryptedDatabase.unlock(db, bad), throwsArgumentError);
      }
      db.close();
    });

    test('prepareFile keeps a readable file', () {
      writeSecret(keyA, 'hello');
      expect(EncryptedDatabase.prepareFile(path, keyA), isFalse);
      expect(File(path).existsSync(), isTrue);
    });

    test('prepareFile discards a file the key cannot open', () {
      writeSecret(keyA, 'hello');
      File('$path-wal').writeAsStringSync('leftover');

      expect(EncryptedDatabase.prepareFile(path, keyB), isTrue);
      expect(File(path).existsSync(), isFalse);
      expect(File('$path-wal').existsSync(), isFalse);
    });

    test('prepareFile does nothing when there is no file yet', () {
      expect(EncryptedDatabase.prepareFile(path, keyA), isFalse);
    });
  });

  group('DatabaseKeyProvider', () {
    test('creates a 64 hex key once and then reuses it', () async {
      final store = MemorySecureStore();
      final provider = DatabaseKeyProvider(store, random: Random(1));

      final first = await provider.obtain();
      final second = await provider.obtain();

      expect(EncryptedDatabase.isValidKey(first), isTrue);
      expect(second, first);
      expect(store.values[DatabaseKeyProvider.storageKey], first);
    });

    test('replaces a corrupted stored key', () async {
      final store = MemorySecureStore()
        ..values[DatabaseKeyProvider.storageKey] = 'not-a-key';
      final key = await DatabaseKeyProvider(store).obtain();
      expect(EncryptedDatabase.isValidKey(key), isTrue);
      expect(store.values[DatabaseKeyProvider.storageKey], key);
    });

    test('memory store supports delete', () async {
      final store = MemorySecureStore();
      await store.write('k', 'v');
      await store.delete('k');
      expect(await store.read('k'), isNull);
    });
  });
}
