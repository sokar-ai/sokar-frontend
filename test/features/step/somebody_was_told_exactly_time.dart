import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: somebody was told exactly {'1'} time
Future<void> somebodyWasToldExactlyTime(WidgetTester tester, String times) async {
  // Prompts re-arrives whenever anything about the list changes, so raising per event rather than
  // per thing would say the same sentence over and over until somebody turned it all off.
  expect(World.notifier.raised, hasLength(int.parse(times)));
}
