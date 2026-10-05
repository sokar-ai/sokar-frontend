import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/e2e.dart';
import '../support/new_person.dart';

/// Usage: the vault is open
Future<void> theVaultIsOpen(WidgetTester tester) async {
  if (!walkingAsANewPerson) return;
  await pumpFor(tester, const Duration(seconds: 2));
  final make = find.byKey(const Key('vault-act'));
  final said = tester.widget<Tooltip>(find.ancestor(of: make, matching: find.byType(Tooltip)).first).message;
  noteTheWindow(tester, 'after the store, its mark says: $said');
  // The mark is the machine's answer, asked again once the terminal was put away.
  expect(said, contains('is open'));
}
