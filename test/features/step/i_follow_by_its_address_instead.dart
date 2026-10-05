import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I follow by its address instead
Future<void> iFollowByItsAddressInstead(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('follow-by-address')));
  await World.settle(tester);
}
