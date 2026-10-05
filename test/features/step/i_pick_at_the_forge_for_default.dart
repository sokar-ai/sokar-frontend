import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I pick {'acme/api'} at the forge for default
Future<void> iPickAtTheForgeForDefault(WidgetTester tester, String repository) async {
  await tester.tap(find.byKey(const Key('default-pick')));
  await World.settle(tester);
  await tester.tap(find.byKey(ValueKey<String>('pick $repository')));
  await World.settle(tester);
}
