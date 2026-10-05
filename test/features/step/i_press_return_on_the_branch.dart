import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I press Return on the branch {'  '}
Future<void> iPressReturnOnTheBranch(WidgetTester tester, String branch) async {
  await tester.tap(find.text('Forward it upstream…'));
  await World.settle(tester);
  await tester.enterText(find.byType(TextField), branch);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await World.settle(tester);
}
