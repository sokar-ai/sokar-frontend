import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine wrote the destination {'weather'}
Future<void> theMachineWroteTheDestination(WidgetTester tester, String name) async {
  final written = World.backend.destinationWrites.where((each) => !each.dryRun).toList();
  expect(written.map((each) => each.name), <String>[name]);
  // As typed, the space included: it is part of what goes before the key.
  expect(written.single.authPrefix, 'Bearer ');
}
