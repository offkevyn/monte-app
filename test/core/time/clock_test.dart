import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/time/clock.dart';

void main() {
  test('SystemClock returns UTC', () {
    expect(const SystemClock().nowUtc().isUtc, isTrue);
  });

  test('FixedClock stays put until advanced', () {
    final clock = FixedClock(DateTime.utc(2026, 11, 5, 12));
    expect(clock.nowUtc(), DateTime.utc(2026, 11, 5, 12));

    clock.advance(const Duration(hours: 15));
    expect(clock.nowUtc(), DateTime.utc(2026, 11, 6, 3));
  });

  test('FixedClock normalizes a local instant to UTC', () {
    final local = DateTime.utc(2026, 11, 5, 12).toLocal();
    expect(FixedClock(local).nowUtc(), DateTime.utc(2026, 11, 5, 12));
  });
}
