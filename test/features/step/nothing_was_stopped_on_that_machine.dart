import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nothing was stopped on that machine
///
/// The offer is a question. Until it is answered, nothing has been run at the far end.
Future<void> nothingWasStoppedOnThatMachine(WidgetTester tester) async {
  expect(World.stopsAsked, isEmpty, reason: 'something was run without being agreed to');
}
