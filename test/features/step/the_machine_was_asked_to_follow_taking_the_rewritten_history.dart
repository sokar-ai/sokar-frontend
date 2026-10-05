import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine was asked to follow {'checkout'} taking the rewritten history
Future<void> theMachineWasAskedToFollowTakingTheRewrittenHistory(WidgetTester tester, String name) async {
  expect(World.backend.follows.where((each) => each.name == name && each.acceptRewrite), hasLength(1));
}
