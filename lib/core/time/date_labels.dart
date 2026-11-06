import 'clock.dart';
import 'local_calendar.dart';
import 'local_date.dart';

/// Dates as the user reads them, in Portuguese, always in the user's day
/// (never the UTC day). Names are written out here instead of loaded from
/// intl, so labels are the same on every device and in tests.
final class DateLabels {
  const DateLabels(this._clock, this._calendar);

  final Clock _clock;
  final LocalCalendar _calendar;

  static const _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', //
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  static const _weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

  LocalDate get today => _calendar.dateOf(_clock.nowUtc());

  /// `Bom dia` / `Boa tarde` / `Boa noite` by the user's hour.
  String greeting() {
    final hour = _calendar.wallClockOf(_clock.nowUtc()).hour;
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  /// `14:32`
  String time(DateTime instant) {
    final local = _calendar.wallClockOf(instant);
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  /// `Hoje`, `Ontem`, or `qua, 04 de nov` (with the year when not this one).
  String day(LocalDate date) {
    final today = this.today;
    if (date == today) return 'Hoje';
    if (date == today.addDays(-1)) return 'Ontem';
    final base =
        '${_weekdays[date.weekday - 1]}, ${_two(date.day)} de '
        '${monthShort(date)}';
    return date.year == today.year ? base : '$base de ${date.year}';
  }

  /// `Hoje · 14:32`, `Ontem · 09:10`, `04/11 · 19:47`.
  String dayAndTime(DateTime instant) {
    final date = _calendar.dateOf(instant);
    final today = this.today;
    final day = switch (date) {
      _ when date == today => 'Hoje',
      _ when date == today.addDays(-1) => 'Ontem',
      _ when date.year == today.year => shortDate(date),
      _ => fullDate(date),
    };
    return '$day · ${time(instant)}';
  }

  /// `30/10`
  String shortDate(LocalDate date) => '${_two(date.day)}/${_two(date.month)}';

  /// `30/10/2026`
  String fullDate(LocalDate date) => '${shortDate(date)}/${date.year}';

  /// `Novembro`
  String month(LocalDate date) {
    final name = _months[date.month - 1];
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  /// `nov`
  String monthShort(LocalDate date) => _months[date.month - 1].substring(0, 3);

  static String _two(int value) => value.toString().padLeft(2, '0');
}
