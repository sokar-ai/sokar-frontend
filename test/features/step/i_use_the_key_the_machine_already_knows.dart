import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I use the key the machine already knows
Future<void> iUseTheKeyTheMachineAlreadyKnows(WidgetTester tester) async {
  // Offered already: the wizard finds the keys it kept before.
  final field = tester.widget<TextField>(find.byKey(const Key('root-key-file')));
  expect(field.controller!.text, endsWith('/.ssh/sokar-the-build-machine'));
  await World.tapInView(tester, 'use-key');
}
