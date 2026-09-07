import 'package:flutter_test/flutter_test.dart';

/// Usage: it lists the agent {'An Agent'}
Future<void> itListsTheAgent(WidgetTester tester, String agent) async {
  expect(find.text(agent), findsWidgets);
}
