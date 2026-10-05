import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked to stop {'systemctl --user stop sokard'}
Future<void> theMachineWasAskedToStop(WidgetTester tester, String part) async {
  expect(World.stopsAsked, isNotEmpty, reason: 'nothing was run on that machine');
  expect(World.stopsAsked.last.join(' '), contains(part));
}
