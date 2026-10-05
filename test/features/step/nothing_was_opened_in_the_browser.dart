import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was opened in the browser
Future<void> nothingWasOpenedInTheBrowser(WidgetTester tester) async {
  expect(World.opened, isEmpty);
}
