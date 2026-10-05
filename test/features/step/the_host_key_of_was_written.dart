import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the host key of {'build.example.test'} was written
Future<void> theHostKeyOfWasWritten(WidgetTester tester, String host) async {
  expect(World.hostKeys.written, <String>[host]);
}
