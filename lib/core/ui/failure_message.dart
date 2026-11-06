import '../failures/failure.dart';

/// User-facing text for each [Failure].
///
/// The `switch` has no `default`: when a new failure is added to the sealed
/// hierarchy, this file stops compiling until it gets a message.
String failureMessage(Failure failure) => switch (failure) {
  NoConnectionFailure() =>
    'Sem internet. Mostrando o que já estava salvo no aparelho.',
  TimeoutFailure() => 'O servidor demorou para responder. Tente de novo.',
  ServerFailure() =>
    'Algo deu errado do nosso lado. Tente de novo em instantes.',
  RateLimitedFailure(:final retryAfter) =>
    retryAfter == null
        ? 'Muitas consultas em pouco tempo. Aguarde um pouco.'
        : 'Muitas consultas em pouco tempo. '
              'Tente de novo em ${retryAfter.inSeconds}s.',
  UnauthorizedFailure() => 'Sua sessão expirou. Entre de novo.',
  InvalidCredentialsFailure() => 'CPF ou senha incorretos.',
  NotFoundFailure() => 'Não encontramos o que você procurou.',
  InvalidDataFailure() =>
    'Recebemos dados num formato inesperado. Já estamos olhando isso.',
  StorageFailure() => 'Não foi possível ler os dados salvos no aparelho.',
  UnexpectedFailure() => 'Algo inesperado aconteceu. Tente de novo.',
};
