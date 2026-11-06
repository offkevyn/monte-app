/// Named routes of the app, in one place so no screen spells a path by hand.
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';

  /// Module of the statement screens.
  static const statement = '/extrato';

  /// Detail of one transaction: `/extrato/transacao/tx_8f3a1c21e000`.
  static const statementDetailPattern = '/transacao/:id';

  static String statementDetail(String id) =>
      '$statement/transacao/${Uri.encodeComponent(id)}';

  /// Module of the crypto screens.
  static const crypto = '/cripto';

  /// Detail of one coin: `/cripto/moeda/bitcoin`.
  static const cryptoCoinPattern = '/moeda/:id';

  static String cryptoCoin(String id) =>
      '$crypto/moeda/${Uri.encodeComponent(id)}';
}
