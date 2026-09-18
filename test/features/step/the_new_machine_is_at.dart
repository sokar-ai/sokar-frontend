import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the new machine is at {'203.0.113.10'}
Future<void> theNewMachineIsAt(WidgetTester tester, String host) async {
  expect(tester.widget<TextField>(find.byKey(const Key('new-host'))).controller!.text, host);
}
