import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was forced
Future<void> itWasForced(WidgetTester tester) async {
  expect(World.backend.deletions.any((asked) => asked.force), isTrue);
}
