import 'package:flutter_test/flutter_test.dart';

/// Usage: it does not say {'It is open and holds nothing'}
Future<void> itDoesNotSay(WidgetTester tester, String words) async {
  expect(find.textContaining(words), findsNothing);
}
