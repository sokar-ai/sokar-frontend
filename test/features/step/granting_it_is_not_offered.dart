import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: granting it is not offered
Future<void> grantingItIsNotOffered(WidgetTester tester) async {
  // The machine refused it already; a button to grant it anyway would ask for the same refusal.
  expect(find.byKey(const Key('widen-apply')), findsNothing);
}
