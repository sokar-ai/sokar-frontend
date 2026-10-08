import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked to refresh {'checkout'}
Future<void> theMachineWasAskedToRefresh(WidgetTester tester, String name) async {
  expect(World.backend.refreshes, <String?>[name]);
}
