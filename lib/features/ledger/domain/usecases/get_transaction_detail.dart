import '../../../../core/failures/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/transaction.dart';
import '../repositories/ledger_repository.dart';

/// Loads one transaction for the detail screen.
///
/// The id comes from the route (`/extrato/transacao/:id`), so it is user
/// controlled input: anything outside the expected shape is answered with
/// "not found" without touching the data layer.
final class GetTransactionDetail {
  const GetTransactionDetail(this._repository);

  final LedgerRepository _repository;

  static final _validId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  Future<Result<Transaction>> call(String id) async {
    final trimmed = id.trim();
    if (!_validId.hasMatch(trimmed)) return const Err(NotFoundFailure());
    return _repository.getTransaction(trimmed);
  }
}
