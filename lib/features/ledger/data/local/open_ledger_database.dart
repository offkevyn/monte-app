import '../../../../core/storage/encrypted_database.dart';
import '../../../../core/storage/open_encrypted_connection.dart';
import 'ledger_database.dart';

/// Opens the encrypted ledger database (`ledger.db`) on the device.
LedgerDatabase openLedgerDatabase(DatabaseKeyProvider keys) =>
    LedgerDatabase(openEncryptedConnection(keys, 'ledger'));
