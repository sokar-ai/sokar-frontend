import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose to {'Stop asking entirely'}
Future<void> iChooseTo(WidgetTester tester, String what) async {
  await tester.tap(find.widgetWithText(OutlinedButton, what));
  await World.settle(tester);
}
