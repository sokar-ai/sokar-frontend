import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: its socket there is not filled in
Future<void> itsSocketThereIsNotFilledIn(WidgetTester tester) async {
  final field = tester.widget<TextField>(find.byKey(const Key('machine-remote-socket')));
  expect(field.controller!.text, isEmpty);
  expect(field.decoration!.hintText, contains('<uid>'));
}
