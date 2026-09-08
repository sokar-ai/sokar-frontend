import 'package:flutter_test/flutter_test.dart';

/// Usage: the project {'unrecorded'} is listed
Future<void> theProjectIsListed(WidgetTester tester, String project) async {
  // Never silently omitted: a project nothing can act on is exactly the one somebody needs to see.
  expect(find.text(project), findsWidgets);
}
