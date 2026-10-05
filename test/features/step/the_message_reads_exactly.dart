import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the message reads exactly {'please look at the diff'}
Future<void> theMessageReadsExactly(WidgetTester tester, String text) async {
  expect(tester.widget<SelectableText>(find.byKey(const Key('held-message-part 0'))).data, text);
}
