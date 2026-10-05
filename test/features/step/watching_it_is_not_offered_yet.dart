import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: watching it is not offered yet
Future<void> watchingItIsNotOfferedYet(WidgetTester tester) async {
  // Nothing is preselected: opening a path somebody else forwarded and starting a process this
  // interface then owns are different commitments, and a default would make that choice.
  // The wizard does not go on to where a machine is watched until a kind is chosen.
  expect(find.byKey(const Key('watch-it')), findsNothing);
  expect(tester.widget<FilledButton>(find.byKey(const Key('wizard-next'))).onPressed, isNull);
}
