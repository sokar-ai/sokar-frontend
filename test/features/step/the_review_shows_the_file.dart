import 'package:flutter_test/flutter_test.dart';

/// Usage: the review shows the file {'lib/money.dart'}
Future<void> theReviewShowsTheFile(WidgetTester tester, String path) async {
  // A tree of what changed, built from the unified diff. It is the honest ceiling: nothing can
  // read a file at a revision, so what surrounds a hunk is not knowable from here.
  expect(find.text(path), findsOneWidget);
}
