import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../step/i_choose_the_command.dart';
import 'world.dart';

/// Opens the project's machines and keys at its forge, from the project, as a person does once it is
/// set up: the dialogs of setting it up are put away first, and the project the machine now
/// follows is chosen.
Future<void> openItsForge(WidgetTester tester) async {
  // The start form follows a binding by itself: put away first, as a person does who came for the keys.
  for (final key in <String>['start-not-now', 'binding-close', 'repositories-close']) {
    if (find.byKey(Key(key)).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(Key(key)).last);
      await World.settle(tester);
    }
  }
  if (find.byKey(const Key('project-forge-dialog')).evaluate().isNotEmpty) return;
  await World.fleet.refresh();
  final project = World.fleet.projects.where((each) => each.project.following != null).last;
  World.fleet.selectProject(project.name);
  await World.settle(tester);
  await iChooseTheCommand(tester, 'Its machines and keys at its forge');
  expect(find.byKey(const Key('project-forge-dialog')), findsOneWidget);
}
