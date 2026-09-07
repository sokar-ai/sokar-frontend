import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was written
Future<void> itWasWritten(WidgetTester tester) async {
  expect(World.backend.changes.last.preview, isFalse);
  // The same words it was previewed with: what was agreed to is the preview.
  expect(World.backend.changes.last.addSets, World.backend.changes.first.addSets);
}
