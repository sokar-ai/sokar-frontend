import 'package:flutter_test/flutter_test.dart';

/// Usage: I ask to see the command it runs
Future<void> iAskToSeeTheCommandItRuns(WidgetTester tester) async {
  await tester.tap(find.text('Show the command it runs'));
  await tester.pumpAndSettle();
}
