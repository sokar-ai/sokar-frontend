import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the sets offered are the ones installed here
///
/// Not a list typed from memory: a set that is not installed on that machine is a refusal waiting
/// at the first task start.
Future<void> theSetsOfferedAreTheOnesInstalledHere(WidgetTester tester) async {
  for (final set in World.backend.theSetsItHas) {
    expect(find.byKey(Key('set-${set.name}')), findsOneWidget,
        reason: '${set.name} is installed here and was not offered');
  }
}
