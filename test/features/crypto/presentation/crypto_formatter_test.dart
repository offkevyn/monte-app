import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/money/money_formatter.dart';
import 'package:monte/features/crypto/domain/entities/crypto_price.dart';
import 'package:monte/features/crypto/presentation/crypto_formatter.dart';

void main() {
  late CryptoFormatter format;

  setUpAll(() async {
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR');
  });

  setUp(() => format = CryptoFormatter(MoneyFormatter()));

  /// Swaps the non-breaking space for a plain one, to keep tests readable.
  String plain(String text) => text.replaceAll(' ', ' ');

  group('price', () {
    test('a real or more has two decimals, rounded half up', () {
      expect(
        plain(format.price(CryptoPrice.parse('438899.39'))),
        r'R$ 438.899,39',
      );
      expect(plain(format.price(CryptoPrice.parse('5.505'))), r'R$ 5,51');
      expect(plain(format.price(CryptoPrice.parse('1'))), r'R$ 1,00');
    });

    test('below a real keeps four significant digits', () {
      expect(
        plain(format.price(CryptoPrice.parse('0.0000712'))),
        r'R$ 0,0000712',
      );
      expect(plain(format.price(CryptoPrice.parse('0.024561'))), r'R$ 0,02456');
      expect(plain(format.price(CryptoPrice.parse('0.5'))), r'R$ 0,50');
      expect(
        plain(format.price(CryptoPrice.parse('0.00000001'))),
        r'R$ 0,00000001',
      );
      expect(plain(format.price(CryptoPrice.zero)), r'R$ 0,00');
    });

    test('rounding up to a whole real switches to cents', () {
      expect(plain(format.price(CryptoPrice.parse('0.99999'))), r'R$ 1,00');
    });

    test('negative and plus signs', () {
      expect(plain(format.price(CryptoPrice.parse('-2'))), r'-R$ 2,00');
      expect(
        plain(format.price(CryptoPrice.parse('2'), showPlusSign: true)),
        r'+R$ 2,00',
      );
    });
  });

  test('percent carries the direction with an arrow', () {
    expect(format.percent(const PercentChange.hundredths(241)), '▲ 2,41%');
    expect(format.percent(const PercentChange.hundredths(-87)), '▼ 0,87%');
    expect(format.percent(const PercentChange.hundredths(0)), '0,00%');
    expect(format.plainPercent(const PercentChange.hundredths(-5)), '0,05%');
  });

  test('change of price', () {
    expect(plain(format.change(CryptoPrice.parse('-56.93'))), r'▼ R$ 56,93');
    expect(
      plain(format.change(CryptoPrice.parse('10330.12'))),
      r'▲ R$ 10.330,12',
    );
    expect(plain(format.change(CryptoPrice.zero)), r'R$ 0,00');
  });

  test('compact totals', () {
    expect(
      plain(format.compact(const Money.cents(870000000000000))),
      r'R$ 8,7 tri',
    );
    expect(
      plain(format.compact(const Money.cents(17500000000000))),
      r'R$ 175 bi',
    );
    expect(plain(format.compact(const Money.cents(12000000000))), r'R$ 120 mi');
    expect(plain(format.compact(const Money.cents(150000))), r'R$ 1,5 mil');
    expect(plain(format.compact(const Money.cents(95000))), r'R$ 950,00');
    expect(plain(format.compact(const Money.cents(-200000000))), r'-R$ 2 mi');
  });
}
