import 'package:flutter_test/flutter_test.dart';

/// Usage: both are shown together
Future<void> bothAreShownTogether(WidgetTester tester) async {
  // One view rather than one per piece of work: somebody watching five windows misses the sixth.
  expect(find.text('api.example.test:443'), findsOneWidget);
  expect(find.text('files.example.test:22'), findsOneWidget);
}
