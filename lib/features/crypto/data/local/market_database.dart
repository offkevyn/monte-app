import 'package:drift/drift.dart';

import '../../../../core/storage/encrypted_database.dart';
import '../../../../core/storage/open_encrypted_connection.dart';

part 'market_database.g.dart';

/// Last known numbers of every coin the app has seen. Prices are integers
/// of 1/100,000,000 real; totals are cents; instants are UTC microseconds.
@DataClassName('CoinRow')
class Coins extends Table {
  TextColumn get id => text()();
  TextColumn get symbol => text()();
  TextColumn get name => text()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get marketCapRank => integer().nullable()();
  IntColumn get priceUnits => integer()();
  IntColumn get change24hHundredths => integer().nullable()();
  IntColumn get priceChange24hUnits => integer().nullable()();
  IntColumn get high24hUnits => integer().nullable()();
  IntColumn get low24hUnits => integer().nullable()();
  IntColumn get marketCapCents => integer().nullable()();
  IntColumn get totalVolumeCents => integer().nullable()();
  IntColumn get updatedAtMicros => integer().nullable()();

  /// When the app saved these numbers (decides if they are still fresh).
  IntColumn get savedAtMicros => integer()();

  /// Name and symbol in lower case without accents, for the offline search.
  TextColumn get searchText => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Which coin is at which position of a saved list page.
@DataClassName('ListEntryRow')
class ListEntries extends Table {
  /// `mostTraded` or `trending`.
  TextColumn get listName => text()();
  IntColumn get page => integer()();
  IntColumn get position => integer()();
  TextColumn get coinId => text()();

  @override
  Set<Column<Object>> get primaryKey => {listName, page, position};
}

/// When each list page was fetched.
@DataClassName('ListPageRow')
class ListPages extends Table {
  TextColumn get listName => text()();
  IntColumn get page => integer()();
  IntColumn get syncedAtMicros => integer()();
  BoolColumn get hasMore => boolean()();
  IntColumn get skippedRecords => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {listName, page};
}

@DataClassName('FavoriteRow')
class Favorites extends Table {
  TextColumn get coinId => text()();
  IntColumn get addedAtMicros => integer()();

  @override
  Set<Column<Object>> get primaryKey => {coinId};
}

@DataClassName('ChartPointRow')
class ChartPoints extends Table {
  TextColumn get coinId => text()();

  /// `day`, `week`, `month` or `year`.
  TextColumn get range => text()();
  IntColumn get atMicros => integer()();
  IntColumn get priceUnits => integer()();

  @override
  Set<Column<Object>> get primaryKey => {coinId, range, atMicros};
}

@DataClassName('ChartStateRow')
class ChartStates extends Table {
  TextColumn get coinId => text()();
  TextColumn get range => text()();
  IntColumn get syncedAtMicros => integer()();

  @override
  Set<Column<Object>> get primaryKey => {coinId, range};
}

@DriftDatabase(
  tables: [Coins, ListEntries, ListPages, Favorites, ChartPoints, ChartStates],
)
class MarketDatabase extends _$MarketDatabase {
  MarketDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

/// Opens `market.db`, encrypted with the same device key as the ledger:
/// favorites say something about the customer, so they get the same care.
MarketDatabase openMarketDatabase(DatabaseKeyProvider keys) =>
    MarketDatabase(openEncryptedConnection(keys, 'market'));
