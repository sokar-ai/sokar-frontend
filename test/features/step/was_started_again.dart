import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: {'sokar-checkout-shell'} was started again
Future<void> wasStartedAgain(WidgetTester tester, String work) async {
  expect(World.backend.resumes, <String>[work]);
}
