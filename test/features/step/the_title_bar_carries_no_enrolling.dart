import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the title bar carries no enrolling
Future<void> theTitleBarCarriesNoEnrolling(WidgetTester tester) async {
  // Beside the lock it read as a task left undone, on every machine this device is not enrolled on.
  expect(find.byKey(const Key('vault-enroll')), findsNothing);
  expect(find.text('Enroll this device'), findsNothing);
}
