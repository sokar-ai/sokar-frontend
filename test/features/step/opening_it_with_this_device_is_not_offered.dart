import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: opening it with this device is not offered
Future<void> openingItWithThisDeviceIsNotOffered(WidgetTester tester) async {
  // A device that is not enrolled has nothing to open it with, so nothing is offered for it.
  expect(find.byKey(const Key('open-with-this-device')), findsNothing);
}
