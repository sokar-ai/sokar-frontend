import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine {'handmade'} is no longer watched
Future<void> theMachineIsNoLongerWatched(WidgetTester tester, String name) async {
  expect(World.machines.all.map((each) => each.name), isNot(contains(name)));
}
