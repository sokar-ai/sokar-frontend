import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I go on with the binding
Future<void> iGoOnWithTheBinding(WidgetTester tester) async {
  await World.tapInView(tester, 'binding-bind');
  await World.settle(tester);
}
