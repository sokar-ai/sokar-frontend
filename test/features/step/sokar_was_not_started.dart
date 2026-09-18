import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: Sokar was not started
Future<void> sokarWasNotStarted(WidgetTester tester) async {
  expect(World.setup.asUserRan, isEmpty);
}
