/// How the app reaches CoinGecko.
///
/// The Demo key comes from `--dart-define-from-file=config/local.json`
/// (ignored by git), never from the source code. Without a key the app
/// still works on CoinGecko's public access, with a lower rate limit.
///
/// Anything compiled into an APK can be extracted from it, so this key is
/// only acceptable because it is a free, read-only Demo key. The next step
/// for production is a small backend (e.g. a Cloud Function with Secret
/// Manager) that holds the key and forwards the requests.
abstract final class CoinGeckoConfig {
  static const baseUrl = 'https://api.coingecko.com/api/v3';

  static const apiKey = String.fromEnvironment('COINGECKO_API_KEY');

  static const keyHeader = 'x-cg-demo-api-key';

  /// Every price is asked in reais.
  static const currency = 'brl';

  static bool get hasKey => apiKey.isNotEmpty;

  static Map<String, String> headers({String key = apiKey}) =>
      key.isEmpty ? const {} : {keyHeader: key};
}
