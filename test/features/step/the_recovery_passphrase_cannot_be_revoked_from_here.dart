import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the recovery passphrase cannot be revoked from here
Future<void> theRecoveryPassphraseCannotBeRevokedFromHere(WidgetTester tester) async {
  expect(find.byKey(const Key('keyslot-slot-0')), findsOneWidget);
  expect(find.byKey(const Key('revoke-slot-0')), findsNothing);
}
