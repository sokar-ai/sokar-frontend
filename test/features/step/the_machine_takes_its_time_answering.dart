import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine takes its time answering
Future<void> theMachineTakesItsTimeAnswering(WidgetTester tester) async {
  World.setup.holdRoot = Completer<void>();
}
