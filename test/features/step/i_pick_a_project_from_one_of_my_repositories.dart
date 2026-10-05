import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I pick a project from one of my repositories
Future<void> iPickAProjectFromOneOfMyRepositories(WidgetTester tester) async {
  await toTheProjects(tester);
  await tapOnScreen(tester, find.byKey(const Key('from-a-repository')));
  await World.settle(tester);
}
