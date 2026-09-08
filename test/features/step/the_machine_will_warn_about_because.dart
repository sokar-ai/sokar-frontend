import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the machine will warn about {'baseImage'} because {'not on this machine yet'}
Future<void> theMachineWillWarnAboutBecause(
    WidgetTester tester, String field, String why) async {
  World.backend.theCreationProblems = <Problem>[
    Problem(field: field, what: why, fatal: false),
  ];
}
