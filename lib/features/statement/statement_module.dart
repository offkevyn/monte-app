import 'package:flutter_modular/flutter_modular.dart';

import '../../app/routes.dart';
import '../ledger/domain/repositories/ledger_repository.dart';
import '../ledger/domain/usecases/get_transaction_detail.dart';
import 'presentation/detail/transaction_detail_cubit.dart';
import 'presentation/detail/transaction_detail_page.dart';

/// Mounted at `/extrato`. The list itself lives in the home tabs (to keep
/// its state); this module owns the named route to the detail.
class StatementModule extends Module {
  @override
  void binds(Injector i) {
    i
      ..add<GetTransactionDetail>(
        () => GetTransactionDetail(Modular.get<LedgerRepository>()),
      )
      ..add<TransactionDetailCubit>(
        () => TransactionDetailCubit(Modular.get<GetTransactionDetail>()),
      );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      Routes.statementDetailPattern,
      child: (_) => TransactionDetailPage(id: r.args.params['id'] as String),
    );
  }
}
