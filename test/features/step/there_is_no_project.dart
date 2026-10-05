import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: there is no project {'payments'}
Future<void> thereIsNoProject(WidgetTester tester, String name) async {
  expect(World.backend.theProjectsItHas.any((each) => each.name == name), isFalse);
}
