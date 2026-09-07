import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_ask_to_close_it.dart';

/// Usage: I close the interface
Future<void> iCloseTheInterface(WidgetTester tester) async {
  // Asking and agreeing, because closing is what takes a forward down and there is no other way
  // to reach that path.
  await iAskToCloseIt(tester);
  await tester.tap(find.widgetWithText(FilledButton, 'Close it'));
  await World.settle(tester);
}
