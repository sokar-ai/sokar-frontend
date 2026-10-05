import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the menu that holds {'Check whether this machine can run anything'} is open with it marked
Future<void> theMenuThatHoldsIsOpenWithItMarked(WidgetTester tester, String command) async {
  final marked = find.byKey(const Key('highlighted'));
  expect(marked, findsOneWidget, reason: 'the finder marked nothing where it went');
  expect(find.descendant(of: marked, matching: find.text(command)), findsOneWidget);
}
