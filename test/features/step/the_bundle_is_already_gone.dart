import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the bundle is already gone
Future<void> theBundleIsAlreadyGone(WidgetTester tester) async {
  World.backend.theBundleIsThere = false;
}
