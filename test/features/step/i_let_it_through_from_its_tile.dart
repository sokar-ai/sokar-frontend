import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I let it through from its tile
Future<void> iLetItThroughFromItsTile(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('tile-let-through')).first);
  await World.settle(tester);
}
