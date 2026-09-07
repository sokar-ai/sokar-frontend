import 'package:flutter_test/flutter_test.dart';

/// Usage: the work {'sokar-checkout-shell'} is listed
Future<void> theWorkIsListed(WidgetTester tester, String work) async {
  expect(find.text(work), findsOneWidget);
}
