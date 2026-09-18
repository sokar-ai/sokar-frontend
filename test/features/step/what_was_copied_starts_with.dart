import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: what was copied starts with {'ssh-ed25519 '}
Future<void> whatWasCopiedStartsWith(WidgetTester tester, String start) async {
  expect(World.copied, hasLength(1));
  expect(World.copied.single, startsWith(start));
  expect(World.copied.single, isNot(contains('PRIVATE')), reason: 'the private key was copied');
}
