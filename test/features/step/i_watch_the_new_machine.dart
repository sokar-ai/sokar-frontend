import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I watch the new machine
Future<void> iWatchTheNewMachine(WidgetTester tester) async {
  // Watching and closing root's way in are the last step, after reaching it.
  for (var i = 0; i < 3 && find.byKey(const Key('watch-new')).evaluate().isEmpty; i++) {
    await World.tapInView(tester, 'setup-next');
  }
  await World.tapInView(tester, 'watch-new');
}
