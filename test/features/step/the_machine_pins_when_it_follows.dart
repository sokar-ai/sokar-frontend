import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine pins {'SHA256:somebody-else'} when it follows
Future<void> theMachinePinsWhenItFollows(WidgetTester tester, String fingerprint) async {
  World.backend.pinsInstead = fingerprint;
}
