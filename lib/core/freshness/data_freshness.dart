import 'package:meta/meta.dart';

import '../failures/failure.dart';

/// How fresh a piece of data is. The UI shows a "last updated at" banner
/// when [isStale] (served from the local copy because the latest sync
/// failed), and can explain why with [syncFailure].
@immutable
final class DataFreshness {
  DataFreshness({
    required DateTime syncedAt,
    this.syncFailure,
    this.skippedRecords = 0,
  }) : syncedAt = syncedAt.toUtc();

  /// Last successful sync with the server, in UTC.
  final DateTime syncedAt;

  /// Why the latest sync attempt failed; `null` when it worked.
  final Failure? syncFailure;

  /// Records the server sent that could not be read and were left out.
  final int skippedRecords;

  bool get isStale => syncFailure != null;

  @override
  bool operator ==(Object other) =>
      other is DataFreshness &&
      other.syncedAt == syncedAt &&
      other.syncFailure == syncFailure &&
      other.skippedRecords == skippedRecords;

  @override
  int get hashCode => Object.hash(syncedAt, syncFailure, skippedRecords);

  @override
  String toString() =>
      'DataFreshness($syncedAt, failure: $syncFailure, '
      'skipped: $skippedRecords)';
}
