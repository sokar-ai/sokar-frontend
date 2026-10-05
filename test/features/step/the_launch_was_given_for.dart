import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the launch was given {'a-provider'} for {'weather'}
Future<void> theLaunchWasGivenFor(WidgetTester tester, String entry, String destination) async {
  expect(World.backend.startedWith.last, <String, String>{entry: destination});
}
