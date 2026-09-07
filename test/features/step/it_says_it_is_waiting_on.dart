import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it says it is waiting on {'api.example.test:443'}
Future<void> itSaysItIsWaitingOn(WidgetTester tester, String destination) async {
  final said = tester.widget<Text>(find.byKey(const Key('waiting-for')));
  expect(said.data, contains(destination));
}
