import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: it shows the digest {'3b1f…'}
Future<void> itShowsTheDigest(WidgetTester tester, String digest) async {
  expect(find.byKey(const Key('agent-artifact-digest')), findsWidgets);
  expect(find.text(digest), findsOneWidget);
}
