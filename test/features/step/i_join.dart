import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I join {'anna'}
Future<void> iJoin(WidgetTester tester, String person) async {
  await tester.enterText(find.byKey(const Key('join-person')), person);
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('join-it')));
  await World.settle(tester);
}
