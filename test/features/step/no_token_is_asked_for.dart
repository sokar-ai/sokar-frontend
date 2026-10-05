import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: no token is asked for
Future<void> noTokenIsAskedFor(WidgetTester tester) async {
  expect(find.byKey(const Key('forge-token')), findsNothing);
}
