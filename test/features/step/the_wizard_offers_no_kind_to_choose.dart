import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the wizard offers no kind to choose
Future<void> theWizardOffersNoKindToChoose(WidgetTester tester) async {
  expect(find.text('Add a user to a machine'), findsOneWidget);
  expect(find.byKey(const Key('machine-new')), findsNothing);
  expect(find.byKey(const Key('machine-raise-it')), findsNothing);
}
