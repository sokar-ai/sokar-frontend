import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked to let {'anna'} join {'checkout'}
Future<void> theMachineWasAskedToLetJoin(WidgetTester tester, String person, String project) async {
  expect(World.backend.joins, <({String project, String person, bool reset})>[
    (project: project, person: person, reset: false),
  ]);
}
