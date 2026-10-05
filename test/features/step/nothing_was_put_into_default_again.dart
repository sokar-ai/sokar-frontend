import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was put into default again
Future<void> nothingWasPutIntoDefaultAgain(WidgetTester tester) async {
  expect(World.backend.addedToDefault, isEmpty);
}
