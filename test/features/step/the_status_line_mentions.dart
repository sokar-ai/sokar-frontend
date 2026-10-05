import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the status line mentions {'Connected'}
Future<void> theStatusLineMentions(WidgetTester tester, String words) async {
  final line = tester.widget<Text>(find.byKey(const Key('status-line')));
  expect(line.data, contains(words));
}
