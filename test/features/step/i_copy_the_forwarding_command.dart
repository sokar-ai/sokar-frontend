import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I copy the forwarding command
Future<void> iCopyTheForwardingCommand(WidgetTester tester) async {
  World.watchTheClipboard(tester);
  await tester.tap(find.byTooltip('Copy the command'));
  await World.settle(tester);
}
