import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it offers to enroll this device
Future<void> itOffersToEnrollThisDevice(WidgetTester tester) async {
  expect(find.byKey(const Key('enroll-this-device')), findsOneWidget);
}
