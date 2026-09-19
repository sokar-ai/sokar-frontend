import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the way to store it is still offered
Future<void> theWayToStoreItIsStillOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('store-send-pasted')), findsOneWidget);
}
