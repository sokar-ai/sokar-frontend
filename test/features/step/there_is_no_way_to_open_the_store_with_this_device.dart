import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: there is no way to open the store with this device
Future<void> thereIsNoWayToOpenTheStoreWithThisDevice(WidgetTester tester) async {
  expect(find.byKey(const Key('unlock-with-this-device')), findsNothing);
}
