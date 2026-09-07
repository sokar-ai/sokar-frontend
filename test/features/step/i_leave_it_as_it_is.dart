import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I leave it as it is
Future<void> iLeaveItAsItIs(WidgetTester tester) async {
  await tester.tap(find.text('Leave it as it is'));
  await World.settle(tester);
}
