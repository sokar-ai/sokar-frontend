import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/ui/operations.dart';

/// Usage: the operation shows {'Building the image'}
Future<void> theOperationShows(WidgetTester tester, String line) async {
  expect(
    find.descendant(
      of: find.byType(OperationOutputView),
      matching: find.text(line),
    ),
    findsOneWidget,
  );
}
