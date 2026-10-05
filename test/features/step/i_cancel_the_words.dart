import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I cancel the words
Future<void> iCancelTheWords(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('words-cancel')));
  await World.settle(tester);
}
