import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the next forward is refused because {'Port 8008 is already in use on this computer.'}
Future<void> theNextForwardIsRefusedBecause(WidgetTester tester, String words) async {
  World.forwardRefused = words;
}
