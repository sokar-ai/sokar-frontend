import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine no longer follows {'checkout'}
Future<void> theMachineNoLongerFollows(WidgetTester tester, String name) async {
  World.backend.noLongerFollowed.add(name);
}
