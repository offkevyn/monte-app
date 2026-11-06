import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/failures/failure.dart';
import '../../../../core/result/result.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/usecases/get_transaction_detail.dart';

sealed class TransactionDetailState {
  const TransactionDetailState();
}

final class DetailLoading extends TransactionDetailState {
  const DetailLoading();
}

final class DetailLoaded extends TransactionDetailState {
  const DetailLoaded(this.transaction);

  final Transaction transaction;
}

final class DetailFailed extends TransactionDetailState {
  const DetailFailed(this.failure);

  final Failure failure;
}

/// ViewModel of the detail screen. Reads the same entity the statement
/// shows, from the same local database.
class TransactionDetailCubit extends Cubit<TransactionDetailState> {
  TransactionDetailCubit(this._getDetail) : super(const DetailLoading());

  final GetTransactionDetail _getDetail;

  Future<void> load(String id) async {
    emit(const DetailLoading());
    final result = await _getDetail(id);
    if (isClosed) return;
    emit(switch (result) {
      Ok(value: final transaction) => DetailLoaded(transaction),
      Err(:final failure) => DetailFailed(failure),
    });
  }
}
