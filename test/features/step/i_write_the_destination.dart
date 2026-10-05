import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I write the destination
Future<void> iWriteTheDestination(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('write-destination')));
  await tester.tap(find.byKey(const Key('write-destination')));
  await World.settle(tester);
}
