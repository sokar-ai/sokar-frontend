import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';
import '../support/world.dart';

/// Usage: I turn the offer down
Future<void> iTurnTheOfferDown(WidgetTester tester) async {
  await tapOnScreen(tester, find.byKey(const Key('not-now')));
  await World.settle(tester);
}
