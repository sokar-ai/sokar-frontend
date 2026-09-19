import 'package:flutter_test/flutter_test.dart';

import 'what_needs_a_person_names_the_project.dart';

/// Usage: what needs a person does not name the project {'checkout'}
Future<void> whatNeedsAPersonDoesNotNameTheProject(WidgetTester tester, String project) async {
  expect(notFollowing(project), findsNothing);
}
