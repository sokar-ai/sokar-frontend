import 'package:flutter_test/flutter_test.dart';

/// Usage: it says the question ran out
Future<void> itSaysTheQuestionRanOut(WidgetTester tester) async {
  expect(find.textContaining('ran out'), findsOneWidget);
}
