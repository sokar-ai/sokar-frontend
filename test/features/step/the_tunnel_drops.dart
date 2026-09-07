import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the tunnel drops
Future<void> theTunnelDrops(WidgetTester tester) async {
  World.backend.lose();
  await World.settle(tester);
}
