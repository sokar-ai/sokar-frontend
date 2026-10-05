import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_walk/guided_walk.dart';

/// Usage: the {'login password'} is blanked in a walk's picture
///
/// What shows a secret sits under a [WalkSecret], which blanks it before a walk takes the window's
/// picture.
Future<void> theIsBlankedInAWalksPicture(WidgetTester tester, String key) async {
  final shown = find.byKey(ValueKey<String>(key));
  expect(shown, findsOneWidget);
  expect(find.ancestor(of: shown, matching: find.byType(WalkSecret)), findsOneWidget);
}
