import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forward was raised for {'the build machine'}
Future<void> theForwardWasRaisedFor(WidgetTester tester, String name) async {
  // What was asked of the transport. `ssh -L <local>:<remote> <host> -N`, and BatchMode so it
  // fails rather than prompting for a passphrase this window has no terminal to take.
  expect(World.forwardsAsked, isNotEmpty);
  final command = World.forwardsAsked.last;
  expect(command.first, 'ssh');
  expect(command, contains('-N'));
  expect(command, contains('BatchMode=yes'));
  expect(command.last, 'user@build.example.test');
}
