import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';

void main() {
  test('failures without data are equal to themselves only', () {
    const failures = <Failure>[
      NoConnectionFailure(),
      TimeoutFailure(),
      UnauthorizedFailure(),
      InvalidCredentialsFailure(),
      NotFoundFailure(),
    ];

    for (final a in failures) {
      for (final b in failures) {
        expect(a == b, identical(a, b), reason: '$a vs $b');
      }
      expect(a.hashCode, a.hashCode);
      expect(a.toString(), endsWith('()'));
    }
  });

  test('failures with data compare by that data', () {
    expect(
      const ServerFailure(statusCode: 500),
      const ServerFailure(statusCode: 500),
    );
    expect(
      const ServerFailure(statusCode: 500).hashCode,
      const ServerFailure(statusCode: 500).hashCode,
    );
    expect(
      const RateLimitedFailure(retryAfter: Duration(seconds: 5)),
      isNot(const RateLimitedFailure(retryAfter: Duration(seconds: 6))),
    );
    expect(const InvalidDataFailure('x'), const InvalidDataFailure('x'));
    expect(const StorageFailure('x'), isNot(const StorageFailure('y')));
    expect(
      const RateLimitedFailure().hashCode,
      const RateLimitedFailure().hashCode,
    );
    expect(
      const InvalidDataFailure('x').hashCode,
      const InvalidDataFailure('x').hashCode,
    );
    expect(
      const StorageFailure('x').hashCode,
      const StorageFailure('x').hashCode,
    );
  });

  test('toString carries the detail for logs', () {
    expect(const ServerFailure(statusCode: 503).toString(), contains('503'));
    expect(
      const RateLimitedFailure(retryAfter: Duration(seconds: 5)).toString(),
      contains('0:00:05'),
    );
    expect(const InvalidDataFailure('bad id').toString(), contains('bad id'));
    expect(const StorageFailure('locked').toString(), contains('locked'));
    expect(
      UnexpectedFailure(StateError('boom'), StackTrace.current).toString(),
      contains('boom'),
    );
  });
}
