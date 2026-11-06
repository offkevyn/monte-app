/// Source of "now". Injected instead of calling `DateTime.now()` directly, so
/// tests can freeze time at the exact edge they want to check.
abstract interface class Clock {
  /// Current instant, always in UTC.
  DateTime nowUtc();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// A clock stopped at [instant]. Useful in tests and in the demo scenarios.
final class FixedClock implements Clock {
  FixedClock(DateTime instant) : _instant = instant.toUtc();

  DateTime _instant;

  @override
  DateTime nowUtc() => _instant;

  /// Moves the clock forward (or back, with a negative duration).
  void advance(Duration duration) => _instant = _instant.add(duration);
}
