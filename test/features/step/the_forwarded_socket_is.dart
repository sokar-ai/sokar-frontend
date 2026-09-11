import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forwarded socket is {'/tmp/sokard-remote.sock'}
Future<void> theForwardedSocketIs(WidgetTester tester, String socket) async {
  await tester.enterText(find.byKey(const Key('machine-socket')), socket);
  await World.settle(tester);
}
