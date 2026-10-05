import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I remove its key at the forge too
Future<void> iRemoveItsKeyAtTheForgeToo(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('default-remove-key')));
  await World.settle(tester);
}
