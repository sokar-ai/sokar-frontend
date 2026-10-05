import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the name offered is {'payments-api'}
Future<void> theNameOfferedIs(WidgetTester tester, String name) async {
  expect(tester.widget<TextField>(find.byKey(const Key('start-name'))).controller!.text, name);
}
