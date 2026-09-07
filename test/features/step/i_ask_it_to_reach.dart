import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I ask it to reach {'files.example.test'}
Future<void> iAskItToReach(WidgetTester tester, String names) async {
  await tester.enterText(find.byKey(const Key('widen-names')), names);
  await World.settle(tester);
}
