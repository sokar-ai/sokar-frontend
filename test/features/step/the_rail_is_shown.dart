import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the rail is shown {false}
Future<void> theRailIsShown(WidgetTester tester, bool shown) async {
  expect(find.byKey(const Key('shell-rail')).hitTestable().evaluate().isNotEmpty, shown);
}
