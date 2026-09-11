import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose the menu entry {'Appearance: dark'}
Future<void> iChooseTheMenuEntry(WidgetTester tester, String entry) async {
  // A pointer alone, deliberately: no shortcut, no finder.
  await tester.tap(find.text(entry).last);
  await World.settle(tester);
}
