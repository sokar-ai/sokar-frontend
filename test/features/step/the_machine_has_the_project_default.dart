import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the machine has the project default
Future<void> theMachineHasTheProjectDefault(WidgetTester tester) async {
  World.backend.theProjectsItHas = <Project>[
    ...World.backend.theProjectsItHas,
    // As Sokar lists it: a file of Sokar's own, where nobody writes, and followed by nobody.
    Project.from(const <String, dynamic>{
      'name': defaultProject,
      'securityClass': 'guarded',
      'file': '/home/me/.local/state/sokar/default/project.yml',
      'following': null,
    }),
  ];
}
