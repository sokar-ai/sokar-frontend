import 'package:flutter_test/flutter_test.dart';

/// Usage: the interface says {'Refused for good'}
Future<void> theInterfaceSays(WidgetTester tester, String words) async {
  expect(find.textContaining(words), findsWidgets);
}
