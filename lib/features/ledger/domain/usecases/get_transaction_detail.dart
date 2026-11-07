import '../../../../core/failures/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/transaction.dart';
import '../repositories/ledger_repository.dart';

/// Loads one transaction for the detail screen: first what is saved on the
/// device (often the summary that came with the statement), then the full
/// record from the server.
///
/// The id comes from the route (`/extrato/transacao/:id`), so it is user
/// controlled input: anything outside the expected shape is answered with
/// "not found" without touching the data layer.
final class GetTransactionDetail {
  const GetTransactionDetail(this._repository);

  final LedgerRepository _repository;

  static final _validId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static String? _clean(String id) {
    final trimmed = id.trim();
    return _validId.hasMatch(trimmed) ? trimmed : null;
  }

  Future<Result<Transaction?>> saved(String id) async {
    final clean = _clean(id);
    if (clean == null) return const Ok(null);
    return _repository.savedTransaction(clean);
  }

  Future<Result<Transaction>> refresh(String id) async {
    final clean = _clean(id);
    if (clean == null) return const Err(NotFoundFailure());
    return _repository.refreshTransaction(clean);
  }
}
