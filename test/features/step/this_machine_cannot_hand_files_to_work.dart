import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: this machine cannot hand files to work
Future<void> thisMachineCannotHandFilesToWork(WidgetTester tester) async {
  // A machine older than hand-in: its tasks carry none of the fields, and the methods are missing.
  World.backend
    ..noHandIn = true
    ..publish(World.work);
  await World.settle(tester);
}
