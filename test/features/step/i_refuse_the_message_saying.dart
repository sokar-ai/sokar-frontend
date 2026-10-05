import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I refuse the message, saying {'not before the tests pass'}
Future<void> iRefuseTheMessageSaying(WidgetTester tester, String reason) async {
  await tester.enterText(find.byKey(const Key('held-message-refuse-reason')), reason);
  await tester.pump();
  await World.tapInView(tester, 'refuse-message');
}
