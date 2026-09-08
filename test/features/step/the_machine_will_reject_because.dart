import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the machine will reject {'name'} because {'a project name cannot contain a slash'}
Future<void> theMachineWillRejectBecause(
    WidgetTester tester, String field, String why) async {
  World.backend.theCreationProblems = <Problem>[
    Problem(field: field, what: why, fatal: true),
  ];
}
