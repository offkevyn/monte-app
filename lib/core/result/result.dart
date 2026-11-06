import '../failures/failure.dart';

/// Outcome of an operation that can fail in an expected way.
///
/// Repositories and use cases return `Result` instead of throwing, so every
/// caller is forced by the compiler to handle both branches:
///
/// ```dart
/// switch (await getBalance()) {
///   case Ok(:final value): emit(Loaded(value));
///   case Err(:final failure): emit(Failed(failure));
/// }
/// ```
///
/// Because the class is `sealed`, a `switch` that forgets one of the cases
/// does not compile.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  bool get isErr => this is Err<T>;

  /// The value when [Ok], otherwise `null`.
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// The failure when [Err], otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  /// Transforms the success value, keeping a failure untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };

  /// Chains another fallible step that only runs on success.
  Future<Result<R>> then<R>(Future<Result<R>> Function(T value) next) async =>
      switch (this) {
        Ok(:final value) => next(value),
        Err(:final failure) => Err(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err($failure)';
}
