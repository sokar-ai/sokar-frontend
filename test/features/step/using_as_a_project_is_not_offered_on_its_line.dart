import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: using {'acme/web'} as a project is not offered on its line
Future<void> usingAsAProjectIsNotOfferedOnItsLine(WidgetTester tester, String repository) async {
  expect(find.byKey(ValueKey<String>('repository $repository')), findsOneWidget);
  // In its menu now: "Work on it on" the machine is not there.
  await tester.tap(find.byKey(ValueKey<String>('forge-repository-menu $repository')));
  await tester.pumpAndSettle();
  expect(find.byKey(ValueKey<String>('bind $repository')), findsNothing);
  await tester.tapAt(Offset.zero);
  await tester.pumpAndSettle();
}
