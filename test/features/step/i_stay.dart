import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I stay
Future<void> iStay(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Stay'));
  await World.settle(tester);
}
