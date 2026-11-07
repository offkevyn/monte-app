import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:monte/core/theme/monte_theme.dart';
import 'package:monte/core/ui/under_construction.dart';

void main() {
  test('the Lottie made for the app parses and lasts 2 seconds', () async {
    final bytes = File(BuildingMonte.asset).readAsBytesSync();
    final composition = await LottieComposition.fromBytes(bytes);
    expect(composition.duration, const Duration(seconds: 2));
    expect(composition.bounds.width, 120);
    expect(composition.bounds.height, 120);
    expect(composition.layers, hasLength(5));
  });

  Future<void> open(WidgetTester tester, {bool reduceMotion = false}) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: MaterialApp(
          theme: MonteTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showUnderConstruction(context, 'O Pix'),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    // The asset loads on real async, which widget tests do not advance.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the animation, the feature and closes', (tester) async {
    await open(tester);
    expect(find.byType(BuildingMonte), findsOneWidget);
    expect(find.text('O Pix tá subindo o morro 🏔'), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.byType(BuildingMonte), findsNothing);
  });

  testWidgets('with reduced motion the drawing is already complete', (
    tester,
  ) async {
    await open(tester, reduceMotion: true);
    final lottie = tester.widget<Lottie>(find.byType(Lottie));
    expect(lottie.controller!.value, 1);
  });
}
