import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/ui/on_visit.dart';

void main() {
  testWidgets('runs the callback on every visit, and stops when gone', (
    tester,
  ) async {
    final visits = StreamController<void>.broadcast();
    addTearDown(visits.close);
    var count = 0;
    await tester.pumpWidget(
      OnVisit(
        visits: visits.stream,
        onVisit: (_) => count++,
        child: const SizedBox(),
      ),
    );

    visits
      ..add(null)
      ..add(null);
    await tester.pump();
    expect(count, 2);

    await tester.pumpWidget(const SizedBox());
    visits.add(null);
    await tester.pump();
    expect(count, 2);
  });

  testWidgets('without a stream it is just its child', (tester) async {
    await tester.pumpWidget(
      OnVisit(
        visits: null,
        onVisit: (_) {},
        child: const Text('x', textDirection: TextDirection.ltr),
      ),
    );
    expect(find.text('x'), findsOneWidget);
  });
}
