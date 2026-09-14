import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no project is selected
Future<void> noProjectIsSelected(WidgetTester tester) async {
  expect(World.fleet.selectedProject, isNull, reason: 'the machine area is narrowed to a project');
  expect(find.byKey(const Key('project-header')), findsNothing);
}
