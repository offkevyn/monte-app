import 'package:drift/drift.dart';

part 'ledger_database.g.dart';

/// Local copy of every transaction. Instants are stored as UTC microseconds
/// (an integer, so ordering and range queries are exact and use the index).
@DataClassName('TransactionRow')
@TableIndex(name: 'idx_transactions_paging', columns: {#occurredAtMicros, #id})
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get description => text()();
  IntColumn get amountCents => integer()();

  /// `credit` or `debit`, same vocabulary as the API.
  TextColumn get direction => text()();
  TextColumn get status => text()();
  IntColumn get occurredAtMicros => integer()();
  TextColumn get paymentMethod => text()();
  TextColumn get category => text()();
  TextColumn get cardLast4 => text().nullable()();
  TextColumn get counterparty => text().nullable()();
  TextColumn get message => text().nullable()();

  /// Description and counterparty in lower case without accents, so the
  /// search follows the same rules as `SearchText` with a plain LIKE.
  TextColumn get searchText => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Single row with what the last successful sync brought.
@DataClassName('SyncStateRow')
class SyncState extends Table {
  IntColumn get id => integer()();
  IntColumn get openingBalanceCents => integer()();
  IntColumn get syncedAtMicros => integer()();

  /// Records the server sent that could not be read.
  IntColumn get skippedRecords => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Transactions, SyncState])
class LedgerDatabase extends _$LedgerDatabase {
  LedgerDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
