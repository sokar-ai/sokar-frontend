import 'package:flutter_test/flutter_test.dart';


/// Usage: the machine is shown as answering
Future<void> theMachineIsShownAsAnswering(WidgetTester tester) async {
  expect(find.byTooltip('mock: Answering'), findsOneWidget);
}
