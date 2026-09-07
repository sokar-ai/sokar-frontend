import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the waiting push
Future<void> iOpenTheWaitingPush(WidgetTester tester) async {
  await tester.tap(find.text('Round to the nearest penny, not away from zero'));
  await World.settle(tester);
}
