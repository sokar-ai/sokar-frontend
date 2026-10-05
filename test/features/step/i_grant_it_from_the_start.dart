import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I grant it from the start
Future<void> iGrantItFromTheStart(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('grant-to-start')));
  await tester.tap(find.byKey(const Key('grant-to-start')));
  await World.settle(tester);
  expect(find.byKey(const Key('grant-dialog')), findsOneWidget);
}
