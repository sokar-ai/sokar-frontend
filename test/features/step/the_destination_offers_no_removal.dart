import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the destination {'search'} offers no removal
Future<void> theDestinationOffersNoRemoval(WidgetTester tester, String name) async {
  expect(find.byKey(ValueKey<String>('destination $name packaged')), findsOneWidget);
  expect(find.byKey(ValueKey<String>('remove-destination $name')), findsNothing);
}
