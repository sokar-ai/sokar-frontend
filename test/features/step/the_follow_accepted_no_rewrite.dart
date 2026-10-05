import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the follow accepted no rewrite
Future<void> theFollowAcceptedNoRewrite(WidgetTester tester) async {
  expect(World.backend.follows, isNotEmpty);
  expect(World.backend.follows.every((each) => !each.acceptRewrite), isTrue);
}
