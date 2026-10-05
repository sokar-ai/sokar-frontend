import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the change {'plan'} was merged here signed with {'SHA256:person'}
Future<void> theChangeWasMergedHereSignedWith(WidgetTester tester, String name, String fingerprint) async {
  expect(World.backend.bundlesTaken, <String>[name]);
  expect(World.workspace.bundlesIn, <String>[name]);
  expect(World.workspace.merges.single, (name: name, fingerprint: fingerprint));
}
