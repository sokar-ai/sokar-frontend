import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine {'the build machine'} says {'Host key verification failed.'}
Future<void> theMachineSays(WidgetTester tester, String name, String words) async {
  // The transport's own sentence, not ours. "Host key verification failed" is a different problem
  // from a machine that is simply not there, and reporting the second sends somebody looking in
  // the wrong place.
  await tester.tap(find.byKey(const Key('machine-switcher')));
  await World.settle(tester);
  final said = tester
      .widgetList<Tooltip>(find.byType(Tooltip))
      .map((tip) => tip.message ?? '')
      .where((message) => message.contains(name));
  expect(said.any((message) => message.contains(words)), isTrue,
      reason: 'the transport said "$words" and nothing showed it: $said');
}
