import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I check the destination
Future<void> iCheckTheDestination(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('check-destination')));
  await tester.tap(find.byKey(const Key('check-destination')));
  await World.settle(tester);
}
