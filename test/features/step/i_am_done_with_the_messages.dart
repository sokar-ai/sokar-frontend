import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I am done with the messages
Future<void> iAmDoneWithTheMessages(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('messages-close')));
  await World.settle(tester);
}
