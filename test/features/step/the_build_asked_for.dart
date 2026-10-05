import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the build asked for {'CACHED'}
///
/// Read off the socket. The depth is the whole decision, and a screen that showed three choices
/// while always sending one would be the worst version of this.
Future<void> theBuildAskedFor(WidgetTester tester, String depth) async {
  expect(World.backend.builds, isNotEmpty, reason: 'nothing was built at all');
  expect(World.backend.builds.last.rebuild, depth);
}
