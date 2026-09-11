import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I confirm
Future<void> iConfirm(WidgetTester tester) async {
  // Separate from asking on purpose: removing work is not something that happens because one
  // entry was chosen from a list.
  await tester.tap(find.widgetWithText(FilledButton, 'Remove it'));
  await World.settle(tester);
}
