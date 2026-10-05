import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the host key of {'root@203.0.113.10'} changed since it was last seen
Future<void> theHostKeyOfChangedSinceItWasLastSeen(WidgetTester tester, String destination) async {
  World.hostKeys.unknown.add(destination);
  World.hostKeys.changed.add(destination);
}
