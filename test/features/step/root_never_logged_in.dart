import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: root never logged in
Future<void> rootNeverLoggedIn(WidgetTester tester) async {
  expect(World.setup.rootLogins, isEmpty);
}
