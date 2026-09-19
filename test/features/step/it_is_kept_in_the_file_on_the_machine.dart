import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it is kept in the file {'/home/me/.ssh/id_work.pub'} on the machine
Future<void> itIsKeptInTheFileOnTheMachine(WidgetTester tester, String path) async {
  await World.choose(tester, 'connection-source', 'source-FILE');
  await tester.enterText(find.byKey(const Key('connection-id')), path);
  await World.settle(tester);
}
