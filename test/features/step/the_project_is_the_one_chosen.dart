import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the project {'payments'} is the one chosen
Future<void> theProjectIsTheOneChosen(WidgetTester tester, String name) async {
  expect(World.fleet.selectedProject?.name, name);
}
