import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I show what that would take back
Future<void> iShowWhatThatWouldTakeBack(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('narrow-preview')));
  await World.settle(tester);
}
