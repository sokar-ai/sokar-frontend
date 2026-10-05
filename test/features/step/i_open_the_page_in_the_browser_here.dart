import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I open the page in the browser here
Future<void> iOpenThePageInTheBrowserHere(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('grant-open')));
  await World.settle(tester);
}
