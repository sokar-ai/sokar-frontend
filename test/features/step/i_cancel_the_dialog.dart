import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I cancel the dialog
Future<void> iCancelTheDialog(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
  await World.settle(tester);
}
