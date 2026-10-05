import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/e2e.dart';

/// Usage: I go back, and the variable {'E2E_NOT_SET'} is still there
Future<void> iGoBackAndTheVariableIsStillThere(WidgetTester tester, String variable) async {
  await tester.tap(find.byKey(const Key('wizard-back')));
  await pumpUntilShown(tester, const Key('connection-variable'));
  expect(tester.widget<TextField>(find.byKey(const Key('connection-variable'))).controller!.text, variable);
}
