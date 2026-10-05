import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the forge holds no key titled {'sokar old-box api/api'} at {'acme/api'}
Future<void> theForgeHoldsNoKeyTitledAt(WidgetTester tester, String title, String repository) async {
  expect(World.forge.keysOf[repository]?.where((each) => each.title == title) ?? const <Object>[], isEmpty);
}
