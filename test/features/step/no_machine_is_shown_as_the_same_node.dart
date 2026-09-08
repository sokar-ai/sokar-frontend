import 'package:flutter_test/flutter_test.dart';

/// Usage: no machine is shown as the same node
Future<void> noMachineIsShownAsTheSameNode(WidgetTester tester) async {
  expect(find.textContaining('the same node as'), findsNothing);
}
