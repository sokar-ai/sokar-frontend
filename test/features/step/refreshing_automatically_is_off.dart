import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: refreshing automatically is off
Future<void> refreshingAutomaticallyIsOff(WidgetTester tester) async {
  expect(World.settings.refreshSeconds, 0);
}
