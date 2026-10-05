import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I copy the diff
Future<void> iCopyTheDiff(WidgetTester tester) async {
  // The common case is somebody wanting the diff in whatever they review in, immediately.
  World.watchTheClipboard(tester);
  await tester.tap(find.text('Copy the diff'));
  await World.settle(tester);
}
