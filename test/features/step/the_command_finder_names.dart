import 'package:flutter_test/flutter_test.dart';

/// Usage: the command finder names {'Refresh from the backend'}
Future<void> theCommandFinderNames(WidgetTester tester, String command) async {
  expect(find.text(command), findsOneWidget);
}
