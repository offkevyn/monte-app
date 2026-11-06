/// Expected problems the app knows how to recover from or explain.
///
/// The hierarchy is `sealed`: the UI maps each one to a message with an
/// exhaustive `switch`, so adding a new failure breaks the build until every
/// screen decides what to show for it.
sealed class Failure {
  const Failure();
}

/// The device has no connection (or the host could not be reached).
final class NoConnectionFailure extends Failure {
  const NoConnectionFailure();

  @override
  bool operator ==(Object other) => other is NoConnectionFailure;

  @override
  int get hashCode => (NoConnectionFailure).hashCode;

  @override
  String toString() => 'NoConnectionFailure()';
}

/// The server took too long to answer.
final class TimeoutFailure extends Failure {
  const TimeoutFailure();

  @override
  bool operator ==(Object other) => other is TimeoutFailure;

  @override
  int get hashCode => (TimeoutFailure).hashCode;

  @override
  String toString() => 'TimeoutFailure()';
}

/// The server answered with an error (5xx or an unexpected 4xx).
final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode});

  final int? statusCode;

  @override
  bool operator ==(Object other) =>
      other is ServerFailure && other.statusCode == statusCode;

  @override
  int get hashCode => Object.hash(ServerFailure, statusCode);

  @override
  String toString() => 'ServerFailure(statusCode: $statusCode)';
}

/// HTTP 429: too many requests. [retryAfter] comes from the `Retry-After`
/// header when the server sends it.
final class RateLimitedFailure extends Failure {
  const RateLimitedFailure({this.retryAfter});

  final Duration? retryAfter;

  @override
  bool operator ==(Object other) =>
      other is RateLimitedFailure && other.retryAfter == retryAfter;

  @override
  int get hashCode => Object.hash(RateLimitedFailure, retryAfter);

  @override
  String toString() => 'RateLimitedFailure(retryAfter: $retryAfter)';
}

/// The session is missing or expired (HTTP 401).
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();

  @override
  bool operator ==(Object other) => other is UnauthorizedFailure;

  @override
  int get hashCode => (UnauthorizedFailure).hashCode;

  @override
  String toString() => 'UnauthorizedFailure()';
}

/// Login rejected: wrong document or password.
final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure();

  @override
  bool operator ==(Object other) => other is InvalidCredentialsFailure;

  @override
  int get hashCode => (InvalidCredentialsFailure).hashCode;

  @override
  String toString() => 'InvalidCredentialsFailure()';
}

/// The requested item does not exist (HTTP 404).
final class NotFoundFailure extends Failure {
  const NotFoundFailure();

  @override
  bool operator ==(Object other) => other is NotFoundFailure;

  @override
  int get hashCode => (NotFoundFailure).hashCode;

  @override
  String toString() => 'NotFoundFailure()';
}

/// A payload arrived but could not be turned into a valid entity.
final class InvalidDataFailure extends Failure {
  const InvalidDataFailure(this.detail);

  /// Developer-facing reason, never shown to the user.
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is InvalidDataFailure && other.detail == detail;

  @override
  int get hashCode => Object.hash(InvalidDataFailure, detail);

  @override
  String toString() => 'InvalidDataFailure($detail)';
}

/// Reading or writing the local database or secure storage failed.
final class StorageFailure extends Failure {
  const StorageFailure(this.detail);

  /// Developer-facing reason, never shown to the user.
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is StorageFailure && other.detail == detail;

  @override
  int get hashCode => Object.hash(StorageFailure, detail);

  @override
  String toString() => 'StorageFailure($detail)';
}

/// Anything not anticipated. Kept so a bug becomes an error screen instead of
/// a crash, while still carrying the original error for logging.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'UnexpectedFailure($error)';
}
