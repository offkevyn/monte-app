import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/dev/scenario_picker.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';
import 'package:monte/core/theme/monte_theme.dart';

void main() {
  late FakeBackendSettings settings;
  late int dataChanges;
  bool? result;

  setUp(() {
    settings = FakeBackendSettings();
    dataChanges = 0;
    settings.addDataListener(() => dataChanges++);
    result = null;
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MonteTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await showScenarioPicker(context, settings),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists every scenario and volume with the current one on', (
    tester,
  ) async {
    await open(tester);
    for (final scenario in FakeScenario.values) {
      expect(find.text(scenario.label), findsOneWidget);
    }
    expect(find.text('10 mil'), findsOneWidget);
    final normal = tester.widget<ChoiceChip>(
      find.byKey(const Key('dev.scenario.normal')),
    );
    expect(normal.selected, isTrue);
  });

  testWidgets('applies the scenario and the volume', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('dev.scenario.rateLimited')));
    await tester.tap(find.byKey(const Key('dev.volume.large')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dev.apply')));
    await tester.pumpAndSettle();

    expect(settings.scenario, FakeScenario.rateLimited);
    expect(settings.volume, FakeVolume.large);
    expect(dataChanges, 1, reason: 'a new volume regenerates the data');
    expect(result, isTrue);
  });

  testWidgets('a scenario alone does not regenerate the data', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('dev.scenario.offline')));
    await tester.tap(find.byKey(const Key('dev.apply')));
    await tester.pumpAndSettle();

    expect(settings.scenario, FakeScenario.offline);
    expect(dataChanges, 0);
    expect(result, isTrue);
  });

  testWidgets('applying without changes or closing reports no change', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('dev.apply')));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
