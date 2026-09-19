import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: trusting is not offered until a key is chosen
Future<void> trustingIsNotOfferedUntilAKeyIsChosen(WidgetTester tester) async {
  expect(tester.widget<OutlinedButton>(find.byKey(const Key('follow-trust-host-key'))).onPressed, isNull);
}
