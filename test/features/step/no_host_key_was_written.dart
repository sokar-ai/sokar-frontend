import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no host key was written
Future<void> noHostKeyWasWritten(WidgetTester tester) async {
  expect(World.hostKeys.written, isEmpty);
}
