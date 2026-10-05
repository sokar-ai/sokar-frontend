import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nobody told any task anything
Future<void> nobodyToldAnyTaskAnything(WidgetTester tester) async {
  expect(World.backend.toldByAPerson, isEmpty);
}
