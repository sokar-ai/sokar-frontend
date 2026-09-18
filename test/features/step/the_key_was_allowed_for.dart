import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the key was allowed for {'agent'}
Future<void> theKeyWasAllowedFor(WidgetTester tester, String user) async {
  final allowed = World.setup.asRootRan.where((script) => script.contains('authorized_keys'));
  expect(allowed, hasLength(1));
  expect(allowed.single, contains("getent passwd '$user'"));
  // The user's own key, never the admin's: that one opens root.
  final admin = Directory('${World.setup.home.path}/.ssh')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('-admin.pub'))
      .map((file) => file.readAsStringSync().trim().split(' ').take(2).join(' '));
  expect(admin, isNotEmpty);
  expect(allowed.single, isNot(contains(admin.single)), reason: "the admin key was allowed for $user");
  expect(allowed.single, contains("'ssh-ed25519 "));
  // With a key and nothing else.
  expect(allowed.single, contains("passwd -l '$user'"));
  expect(allowed.single, contains('AuthenticationMethods publickey'));
}
