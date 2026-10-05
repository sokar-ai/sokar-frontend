import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I start to drop the request and cancel
Future<void> iStartToDropTheRequestAndCancel(WidgetTester tester) async {
  await tester.tap(find.text('Drop the request'));
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('words-cancel')));
  await World.settle(tester);
}
