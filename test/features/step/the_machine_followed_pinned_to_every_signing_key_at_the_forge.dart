import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine followed {'api'} pinned to every signing key at the forge
Future<void> theMachineFollowedPinnedToEverySigningKeyAtTheForge(WidgetTester tester, String project) async {
  final followed = World.backend.follows.last;
  expect(followed.name, project);
  expect(followed.signers, <String>['ssh-ed25519 AAAAperson', 'ssh-ed25519 AAAAdesktop']);
  expect(followed.signedBy, isNull, reason: 'one key or several, never both');
}
