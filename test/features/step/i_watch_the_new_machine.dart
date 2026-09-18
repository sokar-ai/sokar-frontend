import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I watch the new machine
Future<void> iWatchTheNewMachine(WidgetTester tester) async {
  await World.tapInView(tester, 'watch-new');
}
