import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the terminal ends saying {'Signed in to An Agent: the credential is stored'}
Future<void> theTerminalEndsSaying(WidgetTester tester, String words) async {
  expect(tester.widget<Text>(find.byKey(const Key('unlock-ended'))).data, contains(words));
}
