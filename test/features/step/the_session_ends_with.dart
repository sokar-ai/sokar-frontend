import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the session ends with {69}
Future<void> theSessionEndsWith(WidgetTester tester, int code) async {
  World.terminals.last.endsWith(code);
  await World.settle(tester);
}
