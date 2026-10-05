import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it says how to get back to work
Future<void> itSaysHowToGetBackToWork(WidgetTester tester) async {
  // Recovery is possible precisely because nothing was removed, and the steps are named because
  // somebody reading this has just had a bad minute.
  expect(find.byKey(const Key('how-to-recover')), findsWidgets);
}
