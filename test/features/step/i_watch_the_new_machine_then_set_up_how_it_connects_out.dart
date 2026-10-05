import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I watch the new machine, then set up how it connects out
Future<void> iWatchTheNewMachineThenSetUpHowItConnectsOut(WidgetTester tester) async {
  for (var i = 0; i < 3 && find.byKey(const Key('watch-new-then-connections')).evaluate().isEmpty; i++) {
    await World.tapInView(tester, 'setup-next');
  }
  await World.tapInView(tester, 'watch-new-then-connections');
}
