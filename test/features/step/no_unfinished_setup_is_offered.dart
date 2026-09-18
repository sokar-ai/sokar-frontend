import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: no unfinished setup is offered
Future<void> noUnfinishedSetupIsOffered(WidgetTester tester) async {
  expect(find.byKey(const Key('resume-setup')), findsNothing);
}
