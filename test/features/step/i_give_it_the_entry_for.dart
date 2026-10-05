import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I give it the entry {'a-provider'} for {'weather'}
Future<void> iGiveItTheEntryFor(WidgetTester tester, String entry, String destination) async {
  await World.openMoreOptions(tester);
  final field = find.byKey(ValueKey<String>('start-credential $entry'));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await World.settle(tester);
  // Matched loosely: a place is listed with its name beside what it is called.
  await tester.tap(find.textContaining(destination).last);
  await World.settle(tester);
}
