import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I put the start away
Future<void> iPutTheStartAway(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Not now').last);
  await World.settle(tester);
}
