import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';

/// Usage: the project {'checkout'} is not listed
Future<void> theProjectIsNotListed(WidgetTester tester, String project) async {
  await lookingAtTheProjects(tester, () async {
    expect(cardFor(project), findsNothing);
  });
}
