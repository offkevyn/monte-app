import 'package:meta/meta.dart';

import '../../../../core/time/local_date.dart';

/// A closed range of calendar days, both ends included, as the user picks it
/// ("from 01/11 to 30/11").
///
/// Converting it to instants is the calendar's job (`LocalCalendar.rangeOf`),
/// which turns it into a half-open UTC range.
@immutable
final class DateSpan {
  /// If [first] comes after [last] the two are swapped: a user who picks the
  /// dates in reverse order meant the same period.
  factory DateSpan(LocalDate first, LocalDate last) =>
      first.isAfter(last) ? DateSpan._(last, first) : DateSpan._(first, last);

  const DateSpan._(this.first, this.last);

  factory DateSpan.singleDay(LocalDate day) => DateSpan._(day, day);

  final LocalDate first;
  final LocalDate last;

  /// Number of days, counting both ends.
  int get lengthInDays => first.daysUntil(last) + 1;

  bool contains(LocalDate day) => !day.isBefore(first) && !day.isAfter(last);

  /// Every day in the span, oldest first.
  Iterable<LocalDate> get days sync* {
    for (var day = first; !day.isAfter(last); day = day.addDays(1)) {
      yield day;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DateSpan && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);

  @override
  String toString() => 'DateSpan($first..$last)';
}

/// Quick period choices shown on the dashboard and in the filter sheet.
enum PeriodPreset {
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  last90Days;

  /// The days this preset covers when the user's today is [today].
  DateSpan resolve(LocalDate today) => switch (this) {
    PeriodPreset.last7Days => DateSpan(today.addDays(-6), today),
    PeriodPreset.last30Days => DateSpan(today.addDays(-29), today),
    PeriodPreset.last90Days => DateSpan(today.addDays(-89), today),
    PeriodPreset.thisMonth => DateSpan(today.firstDayOfMonth, today),
    PeriodPreset.lastMonth => () {
      final lastDayOfPrevious = today.firstDayOfMonth.addDays(-1);
      return DateSpan(lastDayOfPrevious.firstDayOfMonth, lastDayOfPrevious);
    }(),
  };
}
