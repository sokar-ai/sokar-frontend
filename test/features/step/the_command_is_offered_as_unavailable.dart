import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the command {'Open the selected work'} is offered as unavailable
Future<void> theCommandIsOfferedAsUnavailable(
    WidgetTester tester, String command) async {
  final tile = tester.widget<ListTile>(
    find.ancestor(of: find.text(command), matching: find.byType(ListTile)),
  );
  expect(tile.enabled, isFalse, reason: '$command should not be runnable now');
  expect((tile.subtitle! as Text).data, contains('unavailable'));
}
