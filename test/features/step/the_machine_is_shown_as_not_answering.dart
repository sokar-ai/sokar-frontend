import 'package:flutter_test/flutter_test.dart';


/// Usage: the machine is shown as not answering
Future<void> theMachineIsShownAsNotAnswering(WidgetTester tester) async {
  expect(find.byTooltip('mock: Not answering'), findsOneWidget);
}
