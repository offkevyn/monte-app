import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/usecases/get_transaction_detail.dart';
import 'package:monte/features/statement/presentation/detail/transaction_detail_cubit.dart';

import '../../helpers/memory_ledger_repository.dart';
import '../../helpers/transactions.dart';

void main() {
  final full = tx(
    id: 'tx_card',
    counterparty: 'Loja',
  ).withDetails(cardLastDigits: '4821', message: 'valeu');
  final summary = Transaction(
    id: full.id,
    description: full.description,
    amount: full.amount,
    type: full.type,
    status: full.status,
    occurredAt: full.occurredAt,
    method: full.method,
    counterparty: full.counterparty,
    detailed: false,
  );

  test('the summary shows at once, then the full record', () async {
    final repository = _SummaryFirst(summary, full);
    final cubit = TransactionDetailCubit(GetTransactionDetail(repository));
    final states = <TransactionDetailState>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.load('tx_card');
    await sub.cancel();

    final first = states.first as DetailLoaded;
    expect(first.transaction.detailed, isFalse);
    expect(first.refreshing, isTrue);
    final last = cubit.state as DetailLoaded;
    expect(last.transaction, full);
    expect(last.refreshing, isFalse);
    await cubit.close();
  });

  test('offline with only the summary: shown, details missing', () async {
    final repository = _SummaryFirst(summary, full)
      ..failWith = const NoConnectionFailure();
    final cubit = TransactionDetailCubit(GetTransactionDetail(repository));
    await cubit.load('tx_card');
    final state = cubit.state as DetailLoaded;
    expect(state.transaction, summary);
    expect(state.missingDetails, isTrue);
    await cubit.close();
  });

  test('not found on the server wins over a saved copy', () async {
    final repository = _SummaryFirst(summary, full)
      ..failWith = const NotFoundFailure();
    final cubit = TransactionDetailCubit(GetTransactionDetail(repository));
    await cubit.load('tx_card');
    expect(cubit.state, isA<DetailFailed>());
    await cubit.close();
  });
}

/// Saved copy is the summary; the server answers the full record.
class _SummaryFirst extends MemoryLedgerRepository {
  _SummaryFirst(this.summary, Transaction full) : super([full]);

  final Transaction summary;

  @override
  Future<Result<Transaction?>> savedTransaction(String id) async => Ok(summary);
}
