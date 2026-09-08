import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the caption sent was empty
Future<void> theCaptionSentWasEmpty(WidgetTester tester) async {
  // Empty clears rather than storing spaces — read off the socket, because a screen that showed
  // the name again while having stored a blank would look identical.
  expect(World.backend.labels, isNotEmpty);
  expect(World.backend.labels.last.label, isEmpty);
}
