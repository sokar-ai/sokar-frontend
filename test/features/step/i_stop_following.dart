import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I stop following
Future<void> iStopFollowing(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('follow')));
  await World.settle(tester);
}
