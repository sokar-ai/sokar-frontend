import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: nothing sokar doctor found is shown
Future<void> nothingSokarDoctorFoundIsShown(WidgetTester tester) async {
  expect(find.byKey(const Key('doctor-found')), findsNothing);
  expect(find.byKey(const Key('ask-doctor-again')), findsNothing);
}
