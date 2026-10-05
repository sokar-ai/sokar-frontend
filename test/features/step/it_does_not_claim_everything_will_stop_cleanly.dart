import 'package:flutter_test/flutter_test.dart';

/// Usage: it does not claim everything will stop cleanly
Future<void> itDoesNotClaimEverythingWillStopCleanly(WidgetTester tester) async {
  // A dry run attempts nothing, so every `surviving` comes back empty — because nothing was
  // tried, not because nothing would survive. Drawing that as a clean stop would be a promise
  // made out of an absence of evidence.
  expect(find.textContaining('cleanly'), findsNothing);
  expect(find.textContaining('nothing will survive'), findsNothing);
  expect(find.textContaining('Still running'), findsNothing);
}
