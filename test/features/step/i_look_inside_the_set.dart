import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I look inside the set {'Container registries'}
Future<void> iLookInsideTheSet(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await World.settle(tester);
}
