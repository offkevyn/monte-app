import '../../../core/time/date_labels.dart';
import '../domain/entities/date_span.dart';
import '../domain/entities/transaction.dart';

/// Portuguese names for ledger values. Kept in the presentation layer: the
/// domain only knows enums.
abstract final class LedgerLabels {
  static String status(TransactionStatus status) => switch (status) {
    TransactionStatus.completed => 'Concluída',
    TransactionStatus.pending => 'Pendente',
    TransactionStatus.failed => 'Falhou',
    TransactionStatus.reversed => 'Estornada',
  };

  static String type(TransactionType type) => switch (type) {
    TransactionType.income => 'Entrada',
    TransactionType.expense => 'Saída',
  };

  static String method(PaymentMethod method) => switch (method) {
    PaymentMethod.pix => 'Pix',
    PaymentMethod.creditCard => 'Crédito',
    PaymentMethod.debitCard => 'Débito',
    PaymentMethod.boleto => 'Boleto',
    PaymentMethod.bankTransfer => 'Transferência',
  };

  static String category(TransactionCategory category) => switch (category) {
    TransactionCategory.groceries => 'Mercado',
    TransactionCategory.food => 'Alimentação',
    TransactionCategory.transport => 'Transporte',
    TransactionCategory.bills => 'Contas',
    TransactionCategory.shopping => 'Compras',
    TransactionCategory.health => 'Saúde',
    TransactionCategory.leisure => 'Lazer',
    TransactionCategory.subscriptions => 'Assinaturas',
    TransactionCategory.salary => 'Salário',
    TransactionCategory.transfer => 'Transferência',
    TransactionCategory.other => 'Outros',
  };

  /// Title of a period: `Novembro`, `Últimos 7 dias`.
  static String periodTitle(PeriodPreset preset, DateLabels dates) =>
      switch (preset) {
        PeriodPreset.thisMonth => dates.month(dates.today),
        PeriodPreset.lastMonth => dates.month(
          dates.today.firstDayOfMonth.addDays(-1),
        ),
        PeriodPreset.last7Days => 'Últimos 7 dias',
        PeriodPreset.last30Days => 'Últimos 30 dias',
        PeriodPreset.last90Days => 'Últimos 90 dias',
      };

  /// Short form for "Entradas · nov": `nov`, `7 dias`.
  static String periodShort(PeriodPreset preset, DateLabels dates) =>
      switch (preset) {
        PeriodPreset.thisMonth => dates.monthShort(dates.today),
        PeriodPreset.lastMonth => dates.monthShort(
          dates.today.firstDayOfMonth.addDays(-1),
        ),
        PeriodPreset.last7Days => '7 dias',
        PeriodPreset.last30Days => '30 dias',
        PeriodPreset.last90Days => '90 dias',
      };

  /// Chip of an active period: the preset name when it matches one,
  /// otherwise the dates (`06/10 – 05/11`).
  static String periodOf(DateSpan span, DateLabels dates) {
    for (final preset in PeriodPreset.values) {
      if (preset.resolve(dates.today) == span) {
        return periodTitle(preset, dates);
      }
    }
    return '${dates.shortDate(span.first)} – ${dates.shortDate(span.last)}';
  }

  /// `Pix recebido · Ana Souza`: the counterparty is added when the
  /// description alone does not say who it was.
  static String title(Transaction transaction) {
    final who = transaction.counterparty;
    final generic = transaction.category == TransactionCategory.transfer;
    return generic && who != null
        ? '${transaction.description} · $who'
        : transaction.description;
  }
}
