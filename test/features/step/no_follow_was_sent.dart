import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no follow was sent
Future<void> noFollowWasSent(WidgetTester tester) async {
  expect(World.backend.checkedUrls, isNotEmpty, reason: 'the machine was not even asked');
  expect(World.backend.follows, isEmpty);
}
