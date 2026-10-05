import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I drop the request, saying {'the rounding is still wrong'}
Future<void> iDropTheRequestSaying(WidgetTester tester, String reason) async {
  await tester.tap(find.text('Drop the request'));
  await World.settle(tester);
  await tester.enterText(find.byKey(const Key('words')), reason);
  await tester.pump();
  await tester.tap(find.byKey(const Key('words-confirm')));
  await World.settle(tester);
}
