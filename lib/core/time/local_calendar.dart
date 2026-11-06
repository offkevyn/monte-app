import 'package:flutter/foundation.dart';

import 'local_date.dart';

/// Converts UTC instants to the user's calendar and back.
///
/// Everything that depends on "which day is it for the user" (grouping the
/// statement by day, "this month" totals, a period filter) receives a
/// [LocalCalendar] instead of calling `toLocal()`. In production it follows
/// the device; in tests it is a fixed offset, so results are the same on any
/// machine, including CI running in UTC.
abstract interface class LocalCalendar {
  /// The day [instant] falls on for the user.
  LocalDate dateOf(DateTime instant);

  /// Wall-clock time of [instant] for the user, for display only (`14:32`).
  /// The returned value is meant for its year/month/day/hour/minute fields.
  DateTime wallClockOf(DateTime instant);

  /// The UTC instant when [date] starts for the user (00:00 local).
  DateTime startOf(LocalDate date);

  /// Every instant that falls on the days from [first] to [last], inclusive,
  /// for the user.
  UtcRange rangeOf(LocalDate first, LocalDate last);
}

/// Follows the device time zone.
final class DeviceCalendar implements LocalCalendar {
  const DeviceCalendar();

  @override
  LocalDate dateOf(DateTime instant) {
    final local = instant.toLocal();
    return LocalDate(local.year, local.month, local.day);
  }

  @override
  DateTime wallClockOf(DateTime instant) => instant.toLocal();

  @override
  DateTime startOf(LocalDate date) =>
      DateTime(date.year, date.month, date.day).toUtc();

  @override
  UtcRange rangeOf(LocalDate first, LocalDate last) =>
      UtcRange(startOf(first), startOf(last.addDays(1)));
}

/// A fixed UTC offset, e.g. `Duration(hours: -3)` for Brasília (Brazil has no
/// daylight saving time since 2019).
final class FixedOffsetCalendar implements LocalCalendar {
  const FixedOffsetCalendar(this.offset);

  /// Brasília time, UTC-3.
  static const brasilia = FixedOffsetCalendar(Duration(hours: -3));

  final Duration offset;

  @override
  LocalDate dateOf(DateTime instant) {
    final shifted = wallClockOf(instant);
    return LocalDate(shifted.year, shifted.month, shifted.day);
  }

  /// Returned as a UTC [DateTime] whose fields hold the local wall clock.
  @override
  DateTime wallClockOf(DateTime instant) => instant.toUtc().add(offset);

  @override
  DateTime startOf(LocalDate date) =>
      DateTime.utc(date.year, date.month, date.day).subtract(offset);

  @override
  UtcRange rangeOf(LocalDate first, LocalDate last) =>
      UtcRange(startOf(first), startOf(last.addDays(1)));
}

/// A half-open interval of instants: [start] is included, [end] is not.
///
/// A period "until 30/11" ends at the start of 01/12, not at 23:59:59. That
/// way a transaction at 23:59:59.999 is still inside, and nothing falls in a
/// gap between two consecutive periods.
@immutable
final class UtcRange {
  UtcRange(DateTime start, DateTime end)
    : start = start.toUtc(),
      end = end.toUtc() {
    if (!this.end.isAfter(this.start)) {
      throw ArgumentError('Range end must be after start: $start..$end');
    }
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime instant) {
    final value = instant.toUtc();
    return !value.isBefore(start) && value.isBefore(end);
  }

  @override
  bool operator ==(Object other) =>
      other is UtcRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'UtcRange($start, $end)';
}
