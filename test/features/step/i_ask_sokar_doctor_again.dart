import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I ask sokar doctor again
Future<void> iAskSokarDoctorAgain(WidgetTester tester) async {
  await World.tapInView(tester, 'ask-doctor-again');
}
