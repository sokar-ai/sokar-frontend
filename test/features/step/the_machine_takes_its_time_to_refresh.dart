import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine takes its time to refresh
Future<void> theMachineTakesItsTimeToRefresh(WidgetTester tester) async {
  World.backend.refreshHeld = Completer<void>();
}
