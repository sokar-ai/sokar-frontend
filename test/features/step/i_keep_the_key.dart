import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I keep the key
Future<void> iKeepTheKey(WidgetTester tester) async {
  await World.tapInView(tester, 'keep-key');
}
