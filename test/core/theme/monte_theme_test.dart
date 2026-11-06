import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/theme/monte_colors.dart';
import 'package:monte/core/theme/monte_theme.dart';
import 'package:monte/core/ui/monte_logo.dart';

void main() {
  test('light and dark themes carry the Monte colors', () {
    expect(MonteTheme.light.extension<MonteColors>(), MonteColors.light);
    expect(MonteTheme.dark.extension<MonteColors>(), MonteColors.dark);
    expect(MonteTheme.dark.brightness, Brightness.dark);
  });

  test('MonteColors lerp goes from one palette to the other', () {
    const a = MonteColors.light;
    const b = MonteColors.dark;
    expect(a.lerp(b, 0).expense, a.expense);
    expect(a.lerp(b, 1).expense, b.expense);
    expect(a.lerp(null, 0.5), a);
    expect(a.copyWith(gold: b.expense).gold, b.expense);
  });

  testWidgets('logo is announced to screen readers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: MonteTheme.light, home: const MonteLogo()),
    );
    expect(find.bySemanticsLabel('Monte'), findsOneWidget);
  });

  testWidgets('logo paints at every animation step', (tester) async {
    for (final progress in [0.0, 0.4, 0.9, 1.0]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: MonteLogo(progress: progress)),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
