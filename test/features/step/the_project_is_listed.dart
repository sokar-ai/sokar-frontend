import 'package:flutter_test/flutter_test.dart';

/// Usage: the project {'checkout'} is listed
Future<void> theProjectIsListed(WidgetTester tester, String project) async {
  expect(find.text(project), findsOneWidget);
}
