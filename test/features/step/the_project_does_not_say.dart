import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'the_project_says.dart';

/// Usage: the project {'billing'} does not say {'7 behind'}
Future<void> theProjectDoesNotSay(WidgetTester tester, String project, String words) async {
  await chooseTheProject(tester, project);
  expect(
    find.descendant(of: find.byKey(const Key('project-header')), matching: find.textContaining(words)),
    findsNothing,
  );
}
