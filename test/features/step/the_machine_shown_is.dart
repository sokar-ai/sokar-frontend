import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the machine shown is {'this machine'}
Future<void> theMachineShownIs(WidgetTester tester, String name) async {
  // Read off the pinned name, not off the model: the criterion is that it is never *ambiguous*,
  // which is a claim about what can be seen without scrolling anything.
  expect(
    tester.widget<Text>(find.byKey(const Key('current-machine'))).data,
    name,
  );
}
