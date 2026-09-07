import 'package:flutter_test/flutter_test.dart';

/// Usage: I select the project {'checkout'}
Future<void> iSelectTheProject(WidgetTester tester, String project) async {
  await tester.tap(find.text(project));
  await tester.pumpAndSettle();
}
