import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'i_start_watching_another_machine.dart';

import '../support/world.dart';

/// Usage: I watch another machine called {'elsewhere'}
Future<void> iWatchAnotherMachineCalled(WidgetTester tester, String name) async {
  await iStartWatchingAnotherMachine(tester);

  await tester.enterText(find.byType(TextField).first, name);
  await World.settle(tester);
  await tester.enterText(find.byType(TextField).last, '/tmp/$name.sock');
  await World.settle(tester);
  await tester.tap(find.byKey(const Key('watch-it')));
  await World.settle(tester);
}
