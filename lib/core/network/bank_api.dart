import 'package:dio/dio.dart';

/// The bank's HTTP client. A named wrapper so dependency injection can tell
/// it apart from the CoinGecko client (both are `Dio`).
final class BankApi {
  const BankApi(this.dio);

  final Dio dio;
}
