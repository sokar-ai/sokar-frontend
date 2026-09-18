import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose the repository {'payments-api'}
Future<void> iChooseTheRepository(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.byKey(Key('start-repository-$name')));
  await tester.tap(find.byKey(Key('start-repository-$name')));
  await World.settle(tester);
}
