import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the user that runs work is offered as {'agent'}
Future<void> theUserThatRunsWorkIsOfferedAs(WidgetTester tester, String user) async {
  expect(tester.widget<TextField>(find.byKey(const Key('work-user-name'))).controller!.text, user);
}
