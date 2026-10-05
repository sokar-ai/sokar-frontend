import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the log was asked from its last {1000} lines
Future<void> theLogWasAskedFromItsLastLines(WidgetTester tester, int lines) async {
  expect(World.backend.tailsAsked.where((each) => !each.formatted).last.last, lines);
}
