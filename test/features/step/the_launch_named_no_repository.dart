import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch named no repository
Future<void> theLaunchNamedNoRepository(WidgetTester tester) async {
  expect(World.backend.starts.last.repository, isNull);
}
