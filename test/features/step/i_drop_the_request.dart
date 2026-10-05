import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I drop the request
Future<void> iDropTheRequest(WidgetTester tester) async {
  await tester.tap(find.text('Drop the request'));
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('words-confirm')));
  await World.settle(tester);
}
