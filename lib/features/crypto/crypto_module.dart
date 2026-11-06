import 'package:flutter_modular/flutter_modular.dart';

import '../../app/routes.dart';
import 'domain/repositories/market_repository.dart';
import 'presentation/detail/coin_detail_cubit.dart';
import 'presentation/detail/coin_detail_page.dart';

/// Mounted at `/cripto`. The list lives in the home tabs (to keep its
/// state); this module owns the named route to a coin.
class CryptoModule extends Module {
  @override
  void binds(Injector i) {
    i.add<CoinDetailCubit>(
      () => CoinDetailCubit(Modular.get<MarketRepository>()),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      Routes.cryptoCoinPattern,
      child: (_) => CoinDetailPage(id: r.args.params['id'] as String),
    );
  }
}
