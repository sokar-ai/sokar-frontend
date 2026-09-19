import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: trusting a host key is not offered
Future<void> trustingAHostKeyIsNotOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('follow-trust-host-key')), findsNothing);
  expect(find.byKey(const Key('host-key-choice')), findsNothing);
}
