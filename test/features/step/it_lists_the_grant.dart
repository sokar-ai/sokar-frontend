import 'package:flutter_test/flutter_test.dart';

/// Usage: it lists the grant {'files.example.test'}
Future<void> itListsTheGrant(WidgetTester tester, String name) async {
  // The name itself, not a count of names. Somebody agreeing to this is entitled to see what
  // they are agreeing to — the same rule the project egress preview follows, and the one a
  // mutant that counted instead of showing slipped past once already.
  expect(find.text('+ $name'), findsOneWidget);
}
