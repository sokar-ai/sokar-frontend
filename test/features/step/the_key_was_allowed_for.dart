import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the key was allowed for {'agents'}
Future<void> theKeyWasAllowedFor(WidgetTester tester, String user) async {
  final allowed = World.setup.asRootRan.where((script) => script.contains('authorized_keys'));
  expect(allowed, hasLength(1));
  expect(allowed.single, contains("getent passwd '$user'"));
  expect(allowed.single, contains("'ssh-ed25519 "));
}
