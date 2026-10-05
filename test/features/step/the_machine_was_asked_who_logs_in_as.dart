import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked who {'user@build.example.test'} logs in as
Future<void> theMachineWasAskedWhoLogsInAs(WidgetTester tester, String host) async {
  expect(World.uidsAsked, contains(host));
}
