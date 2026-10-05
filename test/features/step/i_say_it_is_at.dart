import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I say it is at {'user@build.example.test'}
Future<void> iSayItIsAt(WidgetTester tester, String host) async {
  await World.onTheWizardsSecondPage(tester);
  await tester.enterText(find.byKey(const Key('machine-host')), host);
  await World.settle(tester);
}
