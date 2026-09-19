import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I follow a repository
Future<void> iFollowARepository(WidgetTester tester) async {
  await tapOnScreen(tester, find.byKey(const Key('follow-a-repository')));
  await World.settle(tester);
}
