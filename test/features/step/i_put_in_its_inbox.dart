import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I put {'stop the migration, the schema changed'} in its inbox
Future<void> iPutInItsInbox(WidgetTester tester, String words) async {
  await tester.enterText(find.byKey(const Key('words')), words);
  await tester.pump();
  await tester.tap(find.byKey(const Key('words-confirm')));
  await World.settle(tester);
}
