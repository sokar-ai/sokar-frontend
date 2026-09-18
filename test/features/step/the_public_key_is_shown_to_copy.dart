import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the public key is shown to copy
Future<void> thePublicKeyIsShownToCopy(WidgetTester tester) async {
  final shown = tester.widget<SelectableText>(find.byKey(const Key('public-key-to-copy')));
  expect(shown.data, startsWith('ssh-ed25519 '));
  expect(shown.data, isNot(contains('PRIVATE')));
  expect(find.byKey(const Key('copy-public-key')), findsOneWidget);
}
