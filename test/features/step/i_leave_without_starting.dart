import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I leave without starting
Future<void> iLeaveWithoutStarting(WidgetTester tester) async {
  await tester.tap(find.text('Not now'));
  await World.settle(tester);
}
