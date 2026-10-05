import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no key was sent to the machine
Future<void> noKeyWasSentToTheMachine(WidgetTester tester) async {
  expect(World.backend.sharesSent, isEmpty);
}
