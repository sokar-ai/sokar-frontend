import 'package:flutter_test/flutter_test.dart';

/// Usage: the project {'billing'} does not say {'7 behind'}
Future<void> theProjectDoesNotSay(
    WidgetTester tester, String project, String words) async {
  expect(find.text(project), findsWidgets, reason: '$project is not on screen at all');
  expect(find.textContaining(words), findsNothing);
}
