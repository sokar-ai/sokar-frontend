import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: {'acme/api'} has a project.yml
Future<void> hasAProjectyml(WidgetTester tester, String name) async {
  World.forge.projects.add(name);
}
