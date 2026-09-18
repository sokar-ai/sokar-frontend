import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I trust the host key
Future<void> iTrustTheHostKey(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('host-key-accept')));
  await World.settle(tester);
}
