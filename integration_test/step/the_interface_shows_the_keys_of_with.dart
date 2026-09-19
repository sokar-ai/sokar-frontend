import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the interface shows the keys of {'github.com'}, with {'SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU'}
Future<void> theInterfaceShowsTheKeysOfWith(WidgetTester tester, String host, String fingerprint) async {
  final says = find.byKey(const Key('follow-says'));
  expect(says, findsOneWidget, reason: 'the follow did not answer with an outcome');
  expect(tester.widget<Text>(says).data, contains('never met that host'));
  expect(find.byKey(ValueKey<String>('host-key $fingerprint')), findsOneWidget);
  expect(find.textContaining('$host offers these keys'), findsOneWidget);
}
