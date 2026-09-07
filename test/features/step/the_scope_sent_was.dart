import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the scope sent was {'RUN_AND_PROJECT'}
Future<void> theScopeSentWas(WidgetTester tester, String scope) async {
  // What went down the socket. "This run" and "this run and the project" are different changes,
  // and a screen that offered one and sent the other would be wrong in the expensive direction.
  expect(World.backend.widenings, isNotEmpty);
  expect(World.backend.widenings.last.scope.wire, scope);
}
