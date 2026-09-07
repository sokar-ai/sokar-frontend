import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the section shown is {'This session'}
Future<void> theSectionShownIs(WidgetTester tester, String section) async {
  expect(World.shell.section.label, section);
}
