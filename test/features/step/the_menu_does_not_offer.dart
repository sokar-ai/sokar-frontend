import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the menu does not offer {'Unlock the vault, so this can start'}
Future<void> theMenuDoesNotOffer(WidgetTester tester, String label) async {
  expect(
    find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is PopupMenuItem)),
    findsNothing,
  );
}
