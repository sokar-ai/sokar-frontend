import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked about the name {'login-7'}
Future<void> theMachineWasAskedAboutTheName(WidgetTester tester, String name) async {
  expect(World.backend.askedAboutNames, contains(name));
}
