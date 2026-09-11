import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the title is {'this machine › checkout'}
Future<void> theTitleIs(WidgetTester tester, String title) async {
  expect(tester.widget<Text>(find.byKey(const Key('app-title'))).data, title);
}
