import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I remove the destination {'weather'}
Future<void> iRemoveTheDestination(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(ValueKey<String>('remove-destination $name')));
  await World.settle(tester);
}
