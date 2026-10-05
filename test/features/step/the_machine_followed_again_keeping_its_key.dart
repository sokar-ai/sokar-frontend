import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine followed {'api'} again, keeping its key
Future<void> theMachineFollowedAgainKeepingItsKey(WidgetTester tester, String project) async {
  final followed = World.backend.follows.last;
  expect(followed.name, project);
  // A follow again names no key: the one pinned before stays.
  expect(followed.signedBy, isNull);
  expect(followed.signers, isNull);
}
