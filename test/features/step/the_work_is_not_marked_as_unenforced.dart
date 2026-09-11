import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';

/// Usage: the work {'sokar-billing-shell'} is not marked as unenforced
Future<void> theWorkIsNotMarkedAsUnenforced(WidgetTester tester, String work) async {
  expect(find.descendant(of: tileFor(work), matching: find.byKey(const Key('unenforced'))),
      findsNothing);
}
