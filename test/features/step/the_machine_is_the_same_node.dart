import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine {'elsewhere'} is the same node
///
/// One node reached two ways — a socket somebody else forwarded beside a tunnel this interface
/// raised, or one host under two spellings. Nothing about the two entries looks alike.
Future<void> theMachineIsTheSameNode(WidgetTester tester, String name) async {
  World.elsewhere.nodeId = World.backend.nodeId;
}
