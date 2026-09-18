import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it does not offer to enroll this device
Future<void> itDoesNotOfferToEnrollThisDevice(WidgetTester tester) async {
  expect(find.byKey(const Key('enroll-this-device')), findsNothing);
}
