import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/storage/encrypted_database.dart';
import 'package:monte/features/ledger/data/local/ledger_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('a version 1 database (full copy) opens empty as version 2', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = Directory.systemTemp.createTempSync('monte_migration_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = p.join(dir.path, 'ledger.db');
    final key = 'd' * 64;

    // The old schema: the whole account plus a single sync row.
    final old = sqlite3.open(path);
    EncryptedDatabase.unlock(old, key);
    old
      ..execute(
        'CREATE TABLE transactions (id TEXT PRIMARY KEY, description TEXT)',
      )
      ..execute("INSERT INTO transactions VALUES ('tx_old', 'Antiga')")
      ..execute(
        'CREATE TABLE sync_state (id INTEGER PRIMARY KEY, '
        'opening_balance_cents INTEGER, synced_at_micros INTEGER)',
      )
      ..execute('PRAGMA user_version = 1')
      ..close();

    final db = LedgerDatabase(
      NativeDatabase(
        File(path),
        setup: (raw) => EncryptedDatabase.unlock(raw, key),
      ),
    );
    addTearDown(db.close);

    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.dashboardState).get(), isEmpty);
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((row) => row.read<String>('name'))
        .get();
    expect(tables, isNot(contains('sync_state')));
    expect(tables, containsAll(['dashboard_state', 'statement_state']));
  });
}
