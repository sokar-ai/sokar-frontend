import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the host key of {'user@build.example.test'} is not known yet
Future<void> theHostKeyOfIsNotKnownYet(WidgetTester tester, String destination) async {
  World.hostKeys.unknown.add(destination);
}
