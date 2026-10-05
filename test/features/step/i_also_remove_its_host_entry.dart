import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I also remove its Host entry
Future<void> iAlsoRemoveItsHostEntry(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('forget-host-entry')));
  await World.settle(tester);
}
