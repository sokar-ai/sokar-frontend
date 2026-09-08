import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the work was set to {'off'}
///
/// Read off the socket, in the daemon's own spelling — the screen names the modes by what they
/// permit, and a label that stopped matching the value it sends would be invisible here.
Future<void> theWorkWasSetTo(WidgetTester tester, String mode) async {
  expect(World.backend.clearances, isNotEmpty, reason: 'nothing was asked of the machine');
  expect(World.backend.clearances.last.mode, mode);
}
