import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the way to store it says {'That is the public half'}
Future<void> theWayToStoreItSays(WidgetTester tester, String words) async {
  // Beside the way to try again, not only on the status line somebody may not be looking at.
  final refused = find.byKey(const Key('store-refused'));
  expect(refused, findsOneWidget);
  expect(tester.widget<Text>(refused).data, contains(words));
}
