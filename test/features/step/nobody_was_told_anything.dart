import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: nobody was told anything
Future<void> nobodyWasToldAnything(WidgetTester tester) async {
  expect(World.notifier.raised, isEmpty);
}
