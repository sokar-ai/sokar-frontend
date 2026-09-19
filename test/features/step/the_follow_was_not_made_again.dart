import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the follow was not made again
Future<void> theFollowWasNotMadeAgain(WidgetTester tester) async {
  expect(World.backend.follows, hasLength(1));
}
