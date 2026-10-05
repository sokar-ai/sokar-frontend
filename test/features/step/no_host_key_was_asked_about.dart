import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no host key was asked about
Future<void> noHostKeyWasAskedAbout(WidgetTester tester) async {
  expect(World.hostKeys.asked, isEmpty);
}
