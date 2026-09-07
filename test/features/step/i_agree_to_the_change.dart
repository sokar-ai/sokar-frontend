import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I agree to the change
Future<void> iAgreeToTheChange(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Make this change'));
  await World.settle(tester);
}
