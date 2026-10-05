import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I begin revoking {'old phone'}
Future<void> iBeginRevoking(WidgetTester tester, String name) async {
  final id = World.backend.keyslotsHeld.singleWhere((each) => each.slot.name == name).slot.id;
  await World.reach(tester, find.byKey(Key('revoke-$id')));
  await tester.tap(find.byKey(Key('revoke-$id')));
  await World.settle(tester);
}
