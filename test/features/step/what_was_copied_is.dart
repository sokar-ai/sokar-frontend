import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: what was copied is {'ssh -L ...'}
Future<void> whatWasCopiedIs(WidgetTester tester, String command) async {
  // The whole line, not a fragment: it is going into a terminal, and a socket path retyped from a
  // screen is a socket path that ends up almost right.
  expect(World.copied, <String>[command]);
}
