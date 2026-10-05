import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the follow was sent with the key {'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5'}
Future<void> theFollowWasSentWithTheKey(WidgetTester tester, String key) async {
  final sent = World.backend.follows.single;
  expect(sent.signedBy, key);
  expect(sent.unverified, isFalse, reason: 'a key and unverified are two instructions, not one');
}
