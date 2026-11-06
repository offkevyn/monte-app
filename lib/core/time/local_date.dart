import 'package:meta/meta.dart';

/// A calendar day as the user sees it (no time, no time zone).
///
/// Transactions are stored as UTC instants; a [LocalDate] only exists after
/// converting an instant with a `LocalCalendar`. Keeping the two types apart
/// stops code from grouping by `instant.day`, which is the UTC day and puts a
/// purchase made at 23:30 in Brasília on the next day.
@immutable
final class LocalDate implements Comparable<LocalDate> {
  /// Throws an [ArgumentError] for a day that does not exist (e.g. 30/02).
  factory LocalDate(int year, int month, int day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError('Invalid date: $year-$month-$day');
    }
    return LocalDate._(year, month, day);
  }

  const LocalDate._(this.year, this.month, this.day);

  factory LocalDate._fromUtcFields(DateTime value) =>
      LocalDate._(value.year, value.month, value.day);

  final int year;
  final int month;
  final int day;

  /// Monday is 1 and Sunday is 7, same as [DateTime.weekday].
  int get weekday => DateTime.utc(year, month, day).weekday;

  LocalDate addDays(int days) =>
      LocalDate._fromUtcFields(DateTime.utc(year, month, day + days));

  LocalDate get firstDayOfMonth => LocalDate._(year, month, 1);

  /// Day 0 of the next month is the last day of this one, which handles
  /// 28, 29, 30 and 31 without a lookup table.
  LocalDate get lastDayOfMonth =>
      LocalDate._fromUtcFields(DateTime.utc(year, month + 1, 0));

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// ISO format, `2026-11-05`.
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
