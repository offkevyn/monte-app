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
  const DetailLoaded(this.transaction, {this.refreshing = false, this.failure});

  final Transaction transaction;

  /// The full record is on its way from the server (thin bar on screen).
  final bool refreshing;

  /// The server could not be reached; what is shown is what was saved.
  final Failure? failure;

  /// Only the summary is known and the server did not answer: some fields
  /// need the network.
  bool get missingDetails =>
      !transaction.detailed && !refreshing && failure != null;
}

final class DetailFailed extends TransactionDetailState {
  const DetailFailed(this.failure);

  final Failure failure;
}

/// ViewModel of the detail screen. Shows what is saved right away (usually
/// the summary that came with the statement), then the full record from
/// the server, which is saved too.
class TransactionDetailCubit extends Cubit<TransactionDetailState> {
  TransactionDetailCubit(this._getDetail) : super(const DetailLoading());

  final GetTransactionDetail _getDetail;

  Future<void> load(String id) async {
    final saved = (await _getDetail.saved(id)).valueOrNull;
    if (isClosed) return;
    emit(
      saved == null
          ? const DetailLoading()
          : DetailLoaded(saved, refreshing: true),
    );

    final result = await _getDetail.refresh(id);
    if (isClosed) return;
    emit(switch (result) {
      Ok(value: final transaction) => DetailLoaded(transaction),
      Err(:final failure) when saved != null && failure is! NotFoundFailure =>
        DetailLoaded(saved, failure: failure),
      Err(:final failure) => DetailFailed(failure),
    });
  }
}
