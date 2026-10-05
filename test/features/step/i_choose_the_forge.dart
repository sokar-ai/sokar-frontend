import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I choose the forge {'GitHub work'}
Future<void> iChooseTheForge(WidgetTester tester, String name) async {
  // A card on the Forges page now (walk 10, the operator).
  await tester.tap(find.byKey(ValueKey<String>('forge $name')));
  await World.settle(tester);
}
