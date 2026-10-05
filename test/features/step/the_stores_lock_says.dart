import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the store's lock says {'The vault is open. Shut it.'}
Future<void> theStoresLockSays(WidgetTester tester, String words) async {
  // Beside the stop, in the machine's title, whatever else is open.
  final button = find.byKey(const Key('vault-act'));
  expect(button, findsOneWidget);
  expect(
    find.ancestor(of: button, matching: find.byTooltip(words)),
    findsOneWidget,
    reason: 'the lock says something else',
  );
}
