import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I send the key {'id_work'} to the machine
Future<void> iSendTheKeyToTheMachine(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.byKey(const Key('store-key-file')));
  await tester.tap(find.byKey(const Key('store-key-file')));
  await World.settle(tester);
  await tester.tap(find.textContaining('/.ssh/$name').last);
  await World.settle(tester);
  await World.tapInView(tester, 'store-send-file');
}
