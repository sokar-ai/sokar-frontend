import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch asked it to {'Fix the rounding and add a test'}
Future<void> theLaunchAskedItTo(WidgetTester tester, String prompt) async {
  expect(World.backend.starts, isNotEmpty);
  expect(World.backend.starts.last.prompt, prompt);
}
