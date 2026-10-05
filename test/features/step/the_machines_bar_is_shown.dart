import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the machine's bar is shown {false}
Future<void> theMachinesBarIsShown(WidgetTester tester, bool shown) async {
  expect(find.byKey(const Key('machine-title')).evaluate().isNotEmpty, shown);
}
