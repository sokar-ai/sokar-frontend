import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked to grant {'jira'}
Future<void> theMachineWasAskedToGrant(WidgetTester tester, String name) async {
  expect(World.backend.authorizing, <String>[name]);
}
