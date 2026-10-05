import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I call it {'schema-work'}
Future<void> iCallIt(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('start-name')), name);
  await World.settle(tester);
}
