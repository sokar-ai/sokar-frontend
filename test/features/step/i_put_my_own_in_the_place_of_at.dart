import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I put my own in the place of {'search'} at {'https://search.internal.example'}
Future<void> iPutMyOwnInThePlaceOfAt(WidgetTester tester, String name, String upstream) async {
  await tester.tap(find.byKey(ValueKey<String>('change-destination $name')));
  await World.settle(tester);
  await tester.enterText(find.byKey(const Key('destination-upstream')), upstream);
  await World.settle(tester);
  for (final button in <String>['check-destination', 'write-destination']) {
    await tester.ensureVisible(find.byKey(Key(button)));
    await tester.tap(find.byKey(Key(button)));
    await World.settle(tester);
  }
}
