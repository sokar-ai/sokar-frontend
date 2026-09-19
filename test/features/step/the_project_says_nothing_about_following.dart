import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'the_project_says.dart';

/// Usage: the project {'checkout'} says nothing about following
Future<void> theProjectSaysNothingAboutFollowing(WidgetTester tester, String project) async {
  await chooseTheProject(tester, project);
  expect(find.byKey(const Key('project-following')), findsNothing);
}
