import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I show what that would grant
Future<void> iShowWhatThatWouldGrant(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('widen-preview')));
  await World.settle(tester);
}
