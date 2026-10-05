import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: the project {'checkout'} says {'3 behind, as of 20 minutes ago'}
///
/// What a project is and how it stands is said in its header, once it is chosen on the left.
Future<void> theProjectSays(WidgetTester tester, String project, String words) async {
  await chooseTheProject(tester, project);
  expect(
    find.descendant(of: find.byKey(const Key('project-header')), matching: find.textContaining(words)),
    findsWidgets,
  );
}

/// Chooses [project] on the left, unless it is the one chosen already.
Future<void> chooseTheProject(WidgetTester tester, String project) async {
  await toTheProjects(tester);
  expect(cardFor(project), findsOneWidget, reason: '$project is not on the page of machines at all');
  if (World.fleet.selectedProject?.name == project) return toTheChosenProject(tester);
  await tapOnScreen(tester, cardFor(project));
  await World.settle(tester);
}
