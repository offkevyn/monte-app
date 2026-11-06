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
      const InvalidCredentialsFailure(attemptsLeft: 2),
      const AccountLockedFailure(),
      const NotFoundFailure(),
      const InvalidDataFailure('amount missing'),
      const StorageFailure('db locked'),
      const CancelledFailure(),
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

  test('login messages count the attempts left and the lock time', () {
    expect(
      failureMessage(const InvalidCredentialsFailure(attemptsLeft: 2)),
      contains('mais 2 tentativas'),
    );
    expect(
      failureMessage(const InvalidCredentialsFailure(attemptsLeft: 1)),
      contains('mais 1 tentativa '),
    );
    expect(
      failureMessage(const InvalidCredentialsFailure()),
      'CPF ou senha incorretos.',
    );
    expect(
      failureMessage(
        const AccountLockedFailure(retryAfter: Duration(seconds: 250)),
      ),
      contains('5 min'),
    );
  });

  test('developer details never leak into the message', () {
    expect(
      failureMessage(const InvalidDataFailure('field "amount" is null')),
      isNot(contains('amount')),
    );
  });
}
