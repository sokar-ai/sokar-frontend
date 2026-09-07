import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I ask it to {'Fix the rounding and add a test'}
Future<void> iAskItTo(WidgetTester tester, String prompt) async {
  await tester.enterText(find.byKey(const Key('start-prompt')), prompt);
  await World.settle(tester);
}
