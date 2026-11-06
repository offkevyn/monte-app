import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/storage/encrypted_database.dart';
import 'package:monte/features/crypto/data/local/market_database.dart';
import 'package:path/path.dart' as p;

/// Encrypted market database in a temporary file, unlocked like the app
/// does. Closed and deleted when the test ends.
MarketDatabase testMarketDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final dir = Directory.systemTemp.createTempSync('monte_market_');
  final db = MarketDatabase(
    NativeDatabase(
      File(p.join(dir.path, 'market.db')),
      setup: (raw) => EncryptedDatabase.unlock(raw, 'd' * 64),
    ),
  );
  addTearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });
  return db;
}
