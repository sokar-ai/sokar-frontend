import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I watch it
Future<void> iWatchIt(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('watch-it')));
  await World.settle(tester);
}
