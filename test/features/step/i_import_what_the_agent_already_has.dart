import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I import what the agent already has
Future<void> iImportWhatTheAgentAlreadyHas(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('import-credential')).first);
  await World.settle(tester);
}
