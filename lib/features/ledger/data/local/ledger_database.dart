import 'package:drift/drift.dart';

part 'ledger_database.g.dart';

/// Transactions saved on the device: the pages already seen, the dashboard
/// period and the details already opened. Instants are stored as UTC
/// microseconds (an integer, so ordering and range queries are exact and
/// use the index).
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
  TextColumn get counterparty => text().nullable()();

  /// Description and counterparty in lower case without accents, so the
  /// search follows the same rules as `SearchText` with a plain LIKE.
  TextColumn get searchText => text()();

  /// Filled by the detail endpoint only.
  TextColumn get cardLast4 => text().nullable()();
  TextColumn get message => text().nullable()();
  BoolColumn get detailed => boolean().withDefault(const Constant(false))();

  /// When the detail screen last loaded it, to keep the latest opened.
  IntColumn get openedAtMicros => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Single row: what the last dashboard refresh brought.
@DataClassName('DashboardStateRow')
class DashboardState extends Table {
  IntColumn get id => integer()();
  IntColumn get balanceCents => integer()();

  /// The period whose transactions were all saved (`yyyy-mm-dd`).
  TextColumn get periodFirst => text()();
  TextColumn get periodLast => text()();

  /// Ids of the pending debits, as a JSON list. Kept apart from the rows'
  /// status: a debit that settled meanwhile simply leaves this list.
  TextColumn get pendingIds => text()();
  IntColumn get syncedAtMicros => integer()();
  IntColumn get skippedRecords => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Single row: when the statement's first page was last fetched.
@DataClassName('StatementStateRow')
class StatementState extends Table {
  IntColumn get id => integer()();
  IntColumn get syncedAtMicros => integer()();
  IntColumn get skippedRecords => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Transactions, DashboardState, StatementState])
class LedgerDatabase extends _$LedgerDatabase {
  LedgerDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  /// Everything here is a copy of what the server has, so a new schema
  /// starts empty instead of migrating column by column: the next screen
  /// that opens downloads what it needs again.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      for (final table in allTables.toList().reversed) {
        await migrator.deleteTable(table.actualTableName);
      }
      await customStatement('DROP TABLE IF EXISTS sync_state');
      await migrator.createAll();
    },
  );
}
