import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: nothing warns about starting
Future<void> nothingWarnsAboutStarting(WidgetTester tester) async {
  // A repository still to choose is the dialog's own choice, not a problem to warn about.
  expect(find.byKey(const Key('not-ready')), findsNothing);
  expect(find.byKey(const Key('what-it-would-cost')), findsNothing);
  expect(find.byKey(const Key('refused-outright')), findsNothing);
}
