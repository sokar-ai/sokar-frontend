import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I forward it onto the branch {'fix-rounding'}
Future<void> iForwardItOntoTheBranch(WidgetTester tester, String branch) async {
  await tester.tap(find.text('Forward it upstream…'));
  await World.settle(tester);
  await tester.enterText(find.byType(TextField), branch);
  await World.settle(tester);
  await tester.tap(find.widgetWithText(FilledButton, 'Forward it'));
  await World.settle(tester);
}
