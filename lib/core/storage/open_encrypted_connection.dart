import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

import 'encrypted_database.dart';

/// Opens the encrypted database file `<name>.db` on the device.
///
/// The file lives in the app support directory (private to the app, not
/// shown to the user). The connection is created lazily: the key is read
/// from the secure store on first use, so building the database object is
/// synchronous and cheap.
DatabaseConnection openEncryptedConnection(
  DatabaseKeyProvider keys,
  String name,
) => DatabaseConnection.delayed(
  Future(() async {
    final key = await keys.obtain();
    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, '$name.db');
    EncryptedDatabase.prepareFile(path, key);
    return DatabaseConnection(
      driftDatabase(
        name: name,
        native: DriftNativeOptions(
          databasePath: _fixedPath(path),
          setup: _unlockWith(key),
        ),
      ),
    );
  }),
);

// drift runs these callbacks in a background isolate. Building them in
// small top-level functions keeps their closures holding only a String,
// which can be sent between isolates.
void Function(CommonDatabase) _unlockWith(String key) =>
    (db) => EncryptedDatabase.unlock(db, key);

Future<String> Function() _fixedPath(String path) =>
    () async => path;
