import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/ui/panes.dart';

/// Usage: the work {'sokar-checkout-shell'} is no longer listed
Future<void> theWorkIsNoLongerListed(WidgetTester tester, String work) async {
  // The effect, not the report. "It says it was removed" and "it is gone" are different claims,
  // and only the second one is what somebody looking at the list can see.
  expect(
    find.descendant(of: find.byType(WorkPane), matching: find.text(work)),
    findsNothing,
  );
}
