import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I pick one of my repositories instead
Future<void> iPickOneOfMyRepositoriesInstead(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('follow-from-a-repository')));
  await World.settle(tester);
}
