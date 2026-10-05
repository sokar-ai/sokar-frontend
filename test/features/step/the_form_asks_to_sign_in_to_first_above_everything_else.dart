import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the form asks to sign in to {'An Agent'} first, above everything else
Future<void> theFormAsksToSignInToFirstAboveEverythingElse(WidgetTester tester, String agent) async {
  final signIn = find.byKey(const Key('start-sign-in'));
  expect(find.descendant(of: signIn, matching: find.text('Sign in to $agent first')), findsOneWidget);
  // Above the fields: what a start needs is seen without scrolling.
  expect(tester.getTopLeft(signIn).dy, lessThan(tester.getTopLeft(find.byKey(const Key('start-agent'))).dy));
}
