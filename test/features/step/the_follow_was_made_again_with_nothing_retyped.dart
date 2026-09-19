import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the follow was made again, with nothing retyped
Future<void> theFollowWasMadeAgainWithNothingRetyped(WidgetTester tester) async {
  expect(World.backend.follows, hasLength(2));
  expect(World.backend.follows.last.url, World.backend.follows.first.url);
  expect(World.backend.follows.last.name, World.backend.follows.first.name);
}
