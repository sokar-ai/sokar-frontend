import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';
import 'i_store_the_credential_from_the_start.dart';

/// Usage: whether work can start is asked again
Future<void> whetherWorkCanStartIsAskedAgain(WidgetTester tester) async {
  expect(World.backend.canStartAsked, greaterThan(askedBeforeStoring));
}
