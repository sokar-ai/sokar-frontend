import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I add it
Future<void> iAddIt(WidgetTester tester) async {
  await World.tapInView(tester, 'connection-add');
}
