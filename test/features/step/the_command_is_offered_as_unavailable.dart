import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the command {'Open the selected work'} is offered as unavailable
Future<void> theCommandIsOfferedAsUnavailable(
    WidgetTester tester, String command) async {
  final entry = find.widgetWithText(ListTile, command);
  await tester.scrollUntilVisible(
    entry,
    60,
    scrollable: find.descendant(
      of: find.byKey(const Key('command-list')),
      matching: find.byType(Scrollable),
    ),
  );

  final tile = tester.widget<ListTile>(entry);
  expect(tile.enabled, isFalse, reason: '$command should not be runnable now');
  expect((tile.subtitle! as Text).data, contains('unavailable'));
}
