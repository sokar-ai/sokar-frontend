import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the follow was sent unverified
Future<void> theFollowWasSentUnverified(WidgetTester tester) async {
  final sent = World.backend.follows.single;
  expect(sent.unverified, isTrue);
  expect(sent.signedBy, isNull);
}
