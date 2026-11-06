import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/storage/encrypted_database.dart';
import 'package:monte/features/ledger/data/local/ledger_database.dart';
import 'package:path/path.dart' as p;

/// Encrypted ledger database in a temporary file (the cipher does not work
/// on in-memory databases), unlocked exactly like the app does. Closed and
/// deleted automatically when the test ends.
LedgerDatabase testLedgerDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final dir = Directory.systemTemp.createTempSync('monte_ledger_');
  final db = LedgerDatabase(
    NativeDatabase(
      File(p.join(dir.path, 'ledger.db')),
      setup: (raw) => EncryptedDatabase.unlock(raw, 'c' * 64),
    ),
  );
  addTearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });
  return db;
}
