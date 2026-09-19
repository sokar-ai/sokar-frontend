import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the follow accepted the rewrite
Future<void> theFollowAcceptedTheRewrite(WidgetTester tester) async {
  expect(World.backend.follows.last.acceptRewrite, isTrue);
}
