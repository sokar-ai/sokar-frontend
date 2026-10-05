import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the entry {'a-provider'} is not offered to give
Future<void> theEntryIsNotOfferedToGive(WidgetTester tester, String entry) async {
  await World.openMoreOptions(tester);
  expect(find.byKey(const Key('start-credentials')), findsOneWidget);
  expect(find.byKey(ValueKey<String>('start-credential $entry')), findsNothing);
}
