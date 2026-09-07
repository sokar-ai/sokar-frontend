import 'package:flutter_test/flutter_test.dart';

/// Usage: it lists {'quay.io'}
Future<void> itLists(WidgetTester tester, String host) async {
  // A set exists so nobody authors host lists by hand, which only works if the name can be seen
  // through.
  expect(find.text(host), findsWidgets);
}
