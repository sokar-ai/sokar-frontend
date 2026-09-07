import 'package:flutter_test/flutter_test.dart';

Future<void> thePlaceholderIsShown(WidgetTester tester) async {
  expect(find.text('Nothing is built yet.'), findsOneWidget);
}
