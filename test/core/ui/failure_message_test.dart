import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/ui/failure_message.dart';

void main() {
  test('every failure has a non-empty message', () {
    final failures = <Failure>[
      const NoConnectionFailure(),
      const TimeoutFailure(),
      const ServerFailure(statusCode: 500),
      const RateLimitedFailure(),
      const UnauthorizedFailure(),
      const InvalidCredentialsFailure(),
      const NotFoundFailure(),
      const InvalidDataFailure('amount missing'),
      const StorageFailure('db locked'),
      UnexpectedFailure(StateError('boom')),
    ];

    for (final failure in failures) {
      expect(failureMessage(failure), isNotEmpty, reason: '$failure');
    }
  });

  test('rate limit tells how long to wait when the server says so', () {
    expect(
      failureMessage(
        const RateLimitedFailure(retryAfter: Duration(seconds: 30)),
      ),
      contains('30s'),
    );
  });

  test('developer details never leak into the message', () {
    expect(
      failureMessage(const InvalidDataFailure('field "amount" is null')),
      isNot(contains('amount')),
    );
  });
}
