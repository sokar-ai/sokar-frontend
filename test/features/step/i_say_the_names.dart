import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I say the names {'files.example.test'}
Future<void> iSayTheNames(WidgetTester tester, String names) async {
  await tester.enterText(find.byKey(const Key('narrow-names')), names);
  await World.settle(tester);
}
