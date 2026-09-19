import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: the machine follows nothing called it
Future<void> theMachineFollowsNothingCalledIt(WidgetTester tester) async {
  // What Sokar answered on the VM for a project left from before following, 2026-09-19.
  World.backend.refuseToUnfollow = const VarlinkException(
      'org.fuin.sokar.Tasks1.NoSuchProject', <String, dynamic>{'project': 'checkout'});
}
