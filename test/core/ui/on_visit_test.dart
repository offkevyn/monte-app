import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/ui/on_visit.dart';

void main() {
  testWidgets('runs the callback on every visit, and stops when gone', (
    tester,
  ) async {
    final visits = StreamController<Visit>.broadcast();
    addTearDown(visits.close);
    final seen = <Visit>[];
    await tester.pumpWidget(
      OnVisit(
        visits: visits.stream,
        onVisit: (_, visit) => seen.add(visit),
        child: const SizedBox(),
      ),
    );

    visits
      ..add(Visit.tab)
      ..add(Visit.resume);
    await tester.pump();
    expect(seen, [Visit.tab, Visit.resume]);

    await tester.pumpWidget(const SizedBox());
    visits.add(Visit.tab);
    await tester.pump();
    expect(seen, hasLength(2));
  });

  testWidgets('without a stream it is just its child', (tester) async {
    await tester.pumpWidget(
      OnVisit(
        visits: null,
        onVisit: (_, _) {},
        child: const Text('x', textDirection: TextDirection.ltr),
      ),
    );
    expect(find.text('x'), findsOneWidget);
  });
}
