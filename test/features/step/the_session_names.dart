import 'package:flutter_test/flutter_test.dart';

/// Usage: the session names {'sokar-billing-shell'}
///
/// Which one somebody is typing into is the question having several open raises, so each has to
/// be named on the screen rather than only held in a list.
Future<void> theSessionNames(WidgetTester tester, String task) async {
  expect(find.textContaining(task), findsWidgets);
}
