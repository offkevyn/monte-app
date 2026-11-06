import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/market_data.dart';
import '../../domain/usecases/market_usecases.dart';

final class CryptoHighlightsState extends Equatable {
  const CryptoHighlightsState({this.loading = true, this.list});

  final bool loading;

  /// `null` when nothing could be loaded: the card hides itself instead of
  /// putting an error on the dashboard, which is about the account.
  final MarketList? list;

  @override
  List<Object?> get props => [loading, list];
}

/// ViewModel of the small crypto card on the dashboard.
class CryptoHighlightsCubit extends Cubit<CryptoHighlightsState> {
  CryptoHighlightsCubit(this._load) : super(const CryptoHighlightsState());

  final LoadHighlights _load;

  Future<void> load({bool forceRefresh = false}) async {
    final result = await _load(forceRefresh: forceRefresh);
    if (isClosed) return;
    emit(
      CryptoHighlightsState(
        loading: false,
        list: switch (result) {
          Ok(:final value) when value.coins.isNotEmpty => value,
          Ok() || Err() => state.list,
        },
      ),
    );
  }
}
