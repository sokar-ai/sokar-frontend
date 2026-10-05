import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was raised for {'elsewhere'}
Future<void> nothingWasRaisedFor(WidgetTester tester, String name) async {
  // The path with no credential handling in it at all: a socket somebody else forwarded is
  // opened exactly as it always was, and nothing is started for it.
  expect(World.forwardsAsked, isEmpty);
}
