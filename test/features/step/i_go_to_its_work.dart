import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go to its work
Future<void> iGoToItsWork(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('its-work')));
  await tester.tap(find.byKey(const Key('its-work')));
  await World.settle(tester);
}
