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
  InvalidCredentialsFailure(:final attemptsLeft) => switch (attemptsLeft) {
    null || 0 => 'CPF ou senha incorretos.',
    1 =>
      'Senha incorreta. Você tem mais 1 tentativa antes do bloqueio '
          'temporário.',
    final left =>
      'Senha incorreta. Você tem mais $left tentativas antes do '
          'bloqueio temporário.',
  },
  AccountLockedFailure(:final retryAfter) =>
    retryAfter == null
        ? 'Acesso bloqueado por segurança. Tente de novo mais tarde.'
        : 'Acesso bloqueado por segurança. Tente de novo em '
              '${(retryAfter.inSeconds / 60).ceil()} min.',
  NotFoundFailure() => 'Não encontramos o que você procurou.',
  InvalidDataFailure() =>
    'Recebemos dados num formato inesperado. Já estamos olhando isso.',
  StorageFailure() => 'Não foi possível ler os dados salvos no aparelho.',
  // Screens ignore cancellations; the text exists so the switch stays total.
  CancelledFailure() => 'Consulta cancelada.',
  UnexpectedFailure() => 'Algo inesperado aconteceu. Tente de novo.',
};
