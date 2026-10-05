import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was told {'plan'} landed on {'main'}
Future<void> theMachineWasToldLandedOn(WidgetTester tester, String name, String branch) async {
  expect(World.backend.landedAsked, <({String name, String branch})>[(name: name, branch: branch)]);
}
