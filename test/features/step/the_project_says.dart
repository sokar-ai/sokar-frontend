import 'package:flutter_test/flutter_test.dart';

/// Usage: the project {'checkout'} says {'3 behind, as of 20 minutes ago'}
Future<void> theProjectSays(WidgetTester tester, String project, String words) async {
  expect(find.text(project), findsWidgets, reason: '$project is not on screen at all');
  expect(find.textContaining(words), findsWidgets);
}
